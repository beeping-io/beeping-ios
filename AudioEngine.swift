//
//  AudioEngine.swift
//  Beeping
//
//  Internal Swift wrapper around `BCAudioUnitController`. Replaces the
//  legacy ObjC `IosAudioController` class.
//
//  Responsibilities:
//    - Configure `AVAudioSession` (category, sample rate, activation).
//    - Hop the real-time-thread `onToken` callback from
//      `BCAudioUnitController` onto a serial dispatch queue, so the
//      consumer (`BeepingCoreWrapper`) sees events on a non-realtime
//      queue and can safely call into Swift state, allocate, log, etc.
//    - Forward `start` / `stop` / `markEmitting` to the underlying
//      controller.
//
//  ## Concurrency model
//
//  `final class @unchecked Sendable` for the same reason as
//  `BeepingCoreWrapper`: the audio render callback cannot `await`, so an
//  actor is not viable. The unchecked conformance is justified because
//  every property is either:
//    - Set once at init and never written again (`_controller`,
//      `_serialQueue`)
//    - Set rarely from the caller's thread before audio starts
//      (`onAudioToken`) — not contentious in practice
//

import AVFoundation
import Foundation

/// The slice of `AVAudioSession` that `AudioEngine` drives. Exists so tests
/// can simulate an activation failure (BEE-2351) — the real abort only
/// reproduces on a device/simulator and cannot be provoked from a unit test.
internal protocol AudioSessionConfiguring: Sendable {
    func setCategory(
        _ category: AVAudioSession.Category,
        mode: AVAudioSession.Mode,
        options: AVAudioSession.CategoryOptions) throws
    func setPreferredSampleRate(_ sampleRate: Double) throws
    func setActive(_ active: Bool) throws

    /// Whether the user has granted microphone access.
    ///
    /// This is the check that actually prevents the BEE-2351 abort.
    /// `setActive(true)` succeeds happily while the permission is `.denied`
    /// — verified on the Simulator — so the session activating tells us
    /// nothing. Starting a `.playAndRecord` RemoteIO without the permission
    /// is what hangs the RPC to the audio daemon and ends in
    /// `_ReportRPCTimeout → abort`.
    var isRecordPermissionGranted: Bool { get }
}

extension AVAudioSession: AudioSessionConfiguring {
    internal func setActive(_ active: Bool) throws {
        try setActive(active, options: [])
    }

    // `recordPermission` is soft-deprecated in favour of
    // `AVAudioApplication.shared.recordPermission` (iOS 17+), but this
    // target still supports iOS 15 and CI builds on Xcode 16 — the same
    // reason `allowBluetooth` keeps its old spelling above. Revisit with
    // BEE-69 / BEE-79.
    internal var isRecordPermissionGranted: Bool {
        recordPermission == .granted
    }
}

internal final class AudioEngine: @unchecked Sendable {

    // MARK: - State

    private let _controller: BCAudioUnitController
    private let _serialQueue = DispatchQueue(label: "io.beeping.audio.events")
    private let log: BeepingLog
    private let _session: any AudioSessionConfiguring

    /// Set by `BeepingCoreWrapper`. Always invoked on `_serialQueue`,
    /// never on the real-time audio thread.
    internal var onAudioToken: (@Sendable (Int32, String?) -> Void)?

    // MARK: - Init

    internal init(
        core: BCNativeCore,
        log: BeepingLog = BeepingLog(category: "audio"),
        session: any AudioSessionConfiguring = AVAudioSession.sharedInstance()
    ) {
        self._controller = BCAudioUnitController(core: core)
        self.log = log
        self._session = session
        // Wire the controller's audio-thread callback to hop onto our
        // serial queue before invoking the consumer's closure.
        self._controller.onToken = { [weak self] token, decoded in
            // RUNS ON REAL-TIME AUDIO THREAD. Do NOT allocate, do NOT take
            // contended locks, do NOT call into Swift actors. The async
            // dispatch below is the only safe escape hatch.
            self?._serialQueue.async { [weak self] in
                self?.onAudioToken?(token, decoded)
            }
        }
    }

    // MARK: - Lifecycle

    /// Activates the audio session and starts the audio unit.
    ///
    /// - Throws: `BeepingError.missingMicrophonePermission` if the session
    ///   could not be activated, or `BeepingError.audioUnitStartFailed` if
    ///   the unit itself refused to start.
    ///
    /// The session is activated **first and the failure is propagated**
    /// rather than logged: starting the audio unit on an inactive session
    /// makes `AURemoteIO::Start()` abort the process from inside Apple's
    /// code (`_ReportRPCTimeout → abort`, ~14 s later). That abort cannot
    /// be caught — `AudioOutputUnitStart` never returns — so the only
    /// defence is not to call it. See BEE-2351.
    internal func start() throws {
        try configureAudioSession()

        // THE check that prevents the abort. Do not reorder below the
        // controller call and do not downgrade to a log: an ungranted
        // permission makes `AudioOutputUnitStart` hang on its RPC to the
        // audio daemon and abort the process ~14 s later, from inside
        // Apple's code, where nothing can catch it (BEE-2351).
        guard _session.isRecordPermissionGranted else {
            log.error("microphone permission not granted — refusing to start audio")
            throw BeepingError.missingMicrophonePermission
        }

        let status = _controller.start()
        guard status == noErr else {
            log.error("AudioOutputUnitStart failed: OSStatus=\(status)")
            throw BeepingError.audioUnitStartFailed(status: status)
        }
    }

    internal func stop() {
        _ = _controller.stop()
    }

    internal func markEmitting(_ flag: Bool) {
        _controller.emitting = flag
    }

    // MARK: - AVAudioSession

    /// - Throws: `BeepingError.missingMicrophonePermission` when the
    ///   session cannot be configured or activated — typically a denied
    ///   microphone permission, or another app holding the session.
    private func configureAudioSession() throws {
        let session = _session
        do {
            // `allowBluetooth` was renamed to `allowBluetoothHFP` in newer
            // SDKs but the symbol is only present in Xcode 17+ / iOS 17+.
            // CI runs Xcode 16.x, where the new spelling doesn't exist
            // yet. Stay on the old spelling until BEE-69 raises Xcode min
            // and BEE-79 drops legacy SDK support.
            try session.setCategory(
                .playAndRecord,
                mode: .default,
                options: [.defaultToSpeaker, .allowBluetooth])
            try session.setPreferredSampleRate(44100)
            try session.setActive(true)
            log.info("AVAudioSession active: .playAndRecord 44.1kHz")
        } catch {
            // Do NOT swallow this. The caller must not reach
            // `_controller.start()` with an inactive session (BEE-2351).
            log.error("AVAudioSession setup failed: \(error)")
            throw BeepingError.missingMicrophonePermission
        }
    }
}
