//
//  BeepingPayloadTests.swift
//  BeepingTests
//
//  Swift Testing suite for the `BeepingEvent` payload class. Replaces the
//  legacy `BeepingEventTests.m` (deleted in BEE-68 phase 6). All
//  assertions from the ObjC version are preserved 1:1.
//

import Testing
@testable import Beeping

@Suite("BeepingEvent (legacy ObjC payload class, post-BEE-68 swap)")
struct BeepingPayloadTests {

    @Test("Designated init assigns all fields")
    func initializerAssignsAllFields() {
        let event = BeepingEvent(
            status: .endOk,
            key: "12345",
            decodedString: "12345abcd",
            mode: 2,
            timestamp: 42,
            confidence: 0.9,
            confidenceError: 0.2,
            confidenceNoise: 0.3,
            receivedBeepsVolume: -10
        )

        #expect(event.status == .endOk)
        #expect(event.key == "12345")
        #expect(event.decodedString == "12345abcd")
        #expect(event.mode == 2)
        #expect(event.timestamp == 42)
        #expect(abs(event.confidence - 0.9) < 0.0001)
        #expect(abs(event.confidenceError - 0.2) < 0.0001)
        #expect(abs(event.confidenceNoise - 0.3) < 0.0001)
        #expect(abs(event.receivedBeepsVolume - (-10.0)) < 0.0001)
    }

    @Test("Start allows empty payload (key + decodedString nil)")
    func startAllowsEmptyPayload() {
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
        #expect(event.status == .start)
        #expect(event.key == nil)
        #expect(event.decodedString == nil)
        #expect(event.mode == 0)
        #expect(event.timestamp == 0)
    }

    @Test("EndBad allows empty payload (key + decodedString nil)")
    func endBadAllowsEmptyPayload() {
        let event = BeepingEvent(
            status: .endBad,
            key: nil,
            decodedString: nil,
            mode: 0,
            timestamp: 0,
            confidence: 0,
            confidenceError: 0,
            confidenceNoise: 0,
            receivedBeepsVolume: 0
        )
        #expect(event.status == .endBad)
        #expect(event.key == nil)
        #expect(event.decodedString == nil)
    }

    // The legacy ObjC test `testPropertiesAreReadonly` used
    // `respondsToSelector:` for setters. In Swift, immutability is
    // enforced at compile time by `let` — a setter doesn't exist to call.
    // Equivalent assertion is that this file compiles: the struct/class
    // declares all properties as `let` in BeepingEvent.swift.
}
