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

internal final class AudioEngine: @unchecked Sendable {

    // MARK: - State

    private let _controller: BCAudioUnitController
    private let _serialQueue = DispatchQueue(label: "io.beeping.audio.events")

    /// Set by `BeepingCoreWrapper`. Always invoked on `_serialQueue`,
    /// never on the real-time audio thread.
    internal var onAudioToken: (@Sendable (Int32, String?) -> Void)?

    // MARK: - Init

    internal init(core: BCNativeCore) {
        self._controller = BCAudioUnitController(core: core)
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

    internal func start() {
        configureAudioSession()
        _ = _controller.start()
    }

    internal func stop() {
        _ = _controller.stop()
    }

    internal func markEmitting(_ flag: Bool) {
        _controller.emitting = flag
    }

    // MARK: - AVAudioSession

    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord,
                                    mode: .default,
                                    options: [.defaultToSpeaker, .allowBluetoothHFP])
            try session.setPreferredSampleRate(44100)
            try session.setActive(true)
        } catch {
            // BEE-74 will replace NSLog with os.Logger + trace-IDs.
            NSLog("[AudioEngine] AVAudioSession setup failed: \(error)")
        }
    }
}
