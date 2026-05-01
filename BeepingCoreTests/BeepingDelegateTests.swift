//
//  BeepingDelegateTests.swift
//  BeepingTests
//
//  Swift Testing suite for `Beeping`'s delegate dispatch behavior.
//  Replaces the legacy `BeepingDelegateTests.m` (deleted in BEE-68 phase 5)
//  which used KVC reflection (`setValue:forKey:@"_beepingCore"`) to
//  inject a stub `BeepingCore`. Swift class internals are not
//  KVC-accessible; we use the internal test seam
//  `_injectEventForTesting(_:)` instead, which exercises the same dispatch
//  rules without needing to fake the audio pipeline.
//

import Testing
@testable import Beeping

/// Spy delegate for verifying which selectors fire and with what data.
@MainActor
final class SpyDelegate: NSObject, BeepingDelegate {
    var beepIdCalls: Int = 0
    var eventCalls: Int = 0
    var lastKey: String?
    var lastEvent: BeepingEvent?

    func beepId(with beepId: String) {
        beepIdCalls += 1
        lastKey = beepId
    }

    func beepingDidReceive(event: BeepingEvent) {
        eventCalls += 1
        lastEvent = event
    }
}

@Suite("Beeping delegate dispatch")
@MainActor
struct BeepingDelegateTests {

    /// Helper that gives every test a fresh delegate wired into the
    /// shared singleton. Tests share the singleton (legacy semantics
    /// preserved) but rotate delegates so they don't interfere.
    private func freshDelegate() -> SpyDelegate {
        let delegate = SpyDelegate()
        Beeping.shared().delegate = delegate
        return delegate
    }

    @Test("EndOk emits both event AND beepId")
    func endOkEmitsEventAndBeepId() {
        let delegate = freshDelegate()
        let event = BeepingEvent(
            status: .endOk,
            key: "12345",
            decodedString: "12345abcd",
            mode: 2,
            timestamp: 99,
            confidence: 0.8,
            confidenceError: 0.1,
            confidenceNoise: 0.2,
            receivedBeepsVolume: -5
        )

        Beeping.shared()._injectEventForTesting(event)

        #expect(delegate.eventCalls == 1)
        #expect(delegate.beepIdCalls == 1)
        #expect(delegate.lastEvent?.status == .endOk)
        #expect(delegate.lastEvent?.key == "12345")
        #expect(delegate.lastKey == "12345")
        #expect(delegate.lastEvent?.decodedString != nil)
    }

    @Test("EndBad emits only event, no beepId")
    func endBadEmitsOnlyEvent() {
        let delegate = freshDelegate()
        let event = BeepingEvent(
            status: .endBad,
            key: nil,
            decodedString: nil,
            mode: 1,
            timestamp: 0,
            confidence: 0.2,
            confidenceError: 0,
            confidenceNoise: 0,
            receivedBeepsVolume: 0
        )

        Beeping.shared()._injectEventForTesting(event)

        #expect(delegate.eventCalls == 1)
        #expect(delegate.beepIdCalls == 0)
        #expect(delegate.lastEvent?.status == .endBad)
    }

    @Test("Start emits only event, no beepId")
    func startEmitsEventOnly() {
        let delegate = freshDelegate()
        let event = BeepingEvent(
            status: .start,
            key: nil,
            decodedString: nil,
            mode: 0,
            timestamp: 0,
            confidence: 0,
            confidenceError: 0,
            confidenceNoise: 0,
            receivedBeepsVolume: 0
        )

        Beeping.shared()._injectEventForTesting(event)

        #expect(delegate.eventCalls == 1)
        #expect(delegate.beepIdCalls == 0)
        #expect(delegate.lastEvent?.status == .start)
    }

    @Test("EndOk with nil key skips beepId (defensive)")
    func endOkWithNilKeySkipsBeepId() {
        let delegate = freshDelegate()
        let event = BeepingEvent(
            status: .endOk,
            key: nil,  // legacy edge case: status endOk but key is nil
            decodedString: nil,
            mode: 0,
            timestamp: 0,
            confidence: 0,
            confidenceError: 0,
            confidenceNoise: 0,
            receivedBeepsVolume: 0
        )

        Beeping.shared()._injectEventForTesting(event)

        #expect(delegate.eventCalls == 1)
        #expect(delegate.beepIdCalls == 0)
    }
}
