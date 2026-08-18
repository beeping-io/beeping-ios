//
//  AudioEngineStartTests.swift
//  BeepingCoreTests
//
//  BEE-2351 — `AudioEngine.start()` used to swallow an AVAudioSession
//  activation failure and start the audio unit anyway. That makes
//  `AURemoteIO::Start()` abort the **process** from inside Apple's code
//  (`_ReportRPCTimeout → abort`, ~14 s later), which no caller can catch
//  because `AudioOutputUnitStart` never returns.
//
//  The regression these tests lock down is therefore not "the error is
//  reported" but "the audio unit is never reached with a dead session".
//  `try configureAudioSession()` short-circuits `start()` by Swift's own
//  semantics, so asserting that `start()` throws *is* asserting that the
//  controller call is not reached.
//

import AVFoundation
import XCTest

@testable import Beeping

// MARK: - Test doubles

/// Fails at whichever step the test asks for, so each leg of
/// `configureAudioSession()` can be exercised independently.
private final class StubAudioSession: AudioSessionConfiguring, @unchecked Sendable {

    enum FailAt {
        case nothing
        case category
        case sampleRate
        case activation
    }

    private let failAt: FailAt
    let isRecordPermissionGranted: Bool
    private(set) var setCategoryCalled = false
    private(set) var setPreferredSampleRateCalled = false
    private(set) var setActiveCalled = false

    init(failAt: FailAt, permissionGranted: Bool = true) {
        self.failAt = failAt
        self.isRecordPermissionGranted = permissionGranted
    }

    struct StubError: Error {}

    func setCategory(
        _ category: AVAudioSession.Category,
        mode: AVAudioSession.Mode,
        options: AVAudioSession.CategoryOptions
    ) throws {
        setCategoryCalled = true
        if failAt == .category { throw StubError() }
    }

    func setPreferredSampleRate(_ sampleRate: Double) throws {
        setPreferredSampleRateCalled = true
        if failAt == .sampleRate { throw StubError() }
    }

    func setActive(_ active: Bool) throws {
        setActiveCalled = true
        if failAt == .activation { throw StubError() }
    }
}

// MARK: - Tests

final class AudioEngineStartTests: XCTestCase {

    private func makeEngine(session: StubAudioSession) -> AudioEngine {
        AudioEngine(core: BCNativeCore(), session: session)
    }

    /// **The regression that matters.** A denied microphone permission must
    /// stop `start()` before the audio unit is reached.
    ///
    /// This is the shape the real crash takes: the session activates
    /// *successfully* with the permission denied (verified on the
    /// Simulator), so nothing upstream signals a problem — and then
    /// `AudioOutputUnitStart` hangs and aborts the process from inside
    /// Apple's code. Checking `setActive` alone would not have caught it.
    func testStartThrowsWhenMicrophonePermissionIsDenied() {
        let session = StubAudioSession(failAt: .nothing, permissionGranted: false)
        let engine = makeEngine(session: session)

        XCTAssertThrowsError(try engine.start()) { error in
            XCTAssertEqual(
                error as? BeepingError, .missingMicrophonePermission,
                "a denied permission must surface as missingMicrophonePermission")
        }
        XCTAssertTrue(
            session.setActiveCalled,
            "the session does activate — the permission is the thing that fails")
    }

    /// The headline regression: a session that refuses to activate must
    /// abort `start()` *before* the audio unit is touched.
    func testStartThrowsWhenSessionCannotActivate() {
        let session = StubAudioSession(failAt: .activation)
        let engine = makeEngine(session: session)

        XCTAssertThrowsError(try engine.start()) { error in
            XCTAssertEqual(
                error as? BeepingError, .missingMicrophonePermission,
                "an inactive session must surface as missingMicrophonePermission")
        }
        XCTAssertTrue(
            session.setActiveCalled,
            "the failure must come from setActive, not from an earlier step")
    }

    /// Guards the ordering: `setActive` is the last call, so a category
    /// failure must short-circuit before it. If this ever inverts, the
    /// engine could reach the audio unit through an untested path.
    func testStartThrowsWhenCategoryFailsWithoutReachingActivation() {
        let session = StubAudioSession(failAt: .category)
        let engine = makeEngine(session: session)

        XCTAssertThrowsError(try engine.start()) { error in
            XCTAssertEqual(error as? BeepingError, .missingMicrophonePermission)
        }
        XCTAssertTrue(session.setCategoryCalled)
        XCTAssertFalse(
            session.setActiveCalled,
            "a failed setCategory must not fall through to setActive")
    }

    func testStartThrowsWhenPreferredSampleRateFails() {
        let session = StubAudioSession(failAt: .sampleRate)
        let engine = makeEngine(session: session)

        XCTAssertThrowsError(try engine.start()) { error in
            XCTAssertEqual(error as? BeepingError, .missingMicrophonePermission)
        }
        XCTAssertFalse(session.setActiveCalled)
    }

    /// Non-regression half: the fix must not stop configuring the session
    /// correctly. All three session calls happen, in order, before the
    /// permission gate.
    ///
    /// Deliberately runs with the permission denied so `start()` stops at
    /// the gate. Letting it through would reach the real
    /// `AudioOutputUnitStart`, which is precisely the call that can abort
    /// the process — the test suite must never depend on it.
    func testSessionIsFullyConfiguredBeforeThePermissionGate() {
        let session = StubAudioSession(failAt: .nothing, permissionGranted: false)
        let engine = makeEngine(session: session)

        XCTAssertThrowsError(try engine.start())

        XCTAssertTrue(session.setCategoryCalled)
        XCTAssertTrue(session.setPreferredSampleRateCalled)
        XCTAssertTrue(
            session.setActiveCalled,
            "the session must be fully configured before the permission is checked")
    }

    /// The real `AVAudioSession` activates even when the microphone
    /// permission is denied — the observation that redirected this fix.
    ///
    /// Asserted as an implication rather than a fixed value: on a host
    /// where the permission happens to be granted there is nothing to
    /// prove, and the audio unit is never touched either way.
    func testRealSessionActivationDoesNotImplyPermission() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(
            .playAndRecord, mode: .default,
            options: [.defaultToSpeaker, .allowBluetooth])
        try session.setPreferredSampleRate(44100)
        try session.setActive(true)

        // Activation succeeded. If the permission is *not* granted, this is
        // exactly the state that used to abort the process, and the SDK
        // must now treat it as unstartable.
        if !session.isRecordPermissionGranted {
            let engine = AudioEngine(core: BCNativeCore(), session: session)
            XCTAssertThrowsError(try engine.start()) { error in
                XCTAssertEqual(error as? BeepingError, .missingMicrophonePermission)
            }
        }
    }
}
