//
//  SendableConformanceTests.swift
//  BeepingTests
//
//  Compile-time gate: every public Sendable type announced by BEE-68
//  phase 3 actually conforms to `Sendable` without `@unchecked`. This
//  file failing to compile is the test failure.
//

import Testing
@testable import Beeping

@Suite("Sendable conformance gates")
struct SendableConformanceTests {

    /// Constraint helper: this generic function only compiles for types
    /// that satisfy `Sendable`. Calling it with a value of type `T` is a
    /// compile-time assertion that `T: Sendable`.
    private func requireSendable<T: Sendable>(_ value: T) {}

    @Test("BeepingEvent is Sendable")
    func eventIsSendable() {
        let event = BeepingEvent(
            status: .start,
            key: nil, decodedString: nil,
            mode: 0, timestamp: 0,
            confidence: 0, confidenceError: 0,
            confidenceNoise: 0, receivedBeepsVolume: 0
        )
        requireSendable(event)
    }

    @Test("BeepingEvent.Status is Sendable")
    func statusIsSendable() {
        requireSendable(BeepingEvent.Status.endOk)
    }

    @Test("BeepingMode is Sendable")
    func modeIsSendable() {
        requireSendable(BeepingMode.all)
    }

    @Test("BeepingError is Sendable")
    func errorIsSendable() {
        requireSendable(BeepingError.audioSessionInterrupted)
        requireSendable(BeepingError.missingMicrophonePermission)
        requireSendable(BeepingError.nativeLibraryNotLoaded)
        requireSendable(BeepingError.decoderInternal(reason: "synthetic"))
    }
}
