//
//  LocalEncoderWireFormatTests.swift
//  BeepingCoreTests
//
//  BEE-2355 — `LocalEncoder` demanded the 9-char wire string from the
//  caller and rejected every valid 5-char key with `decoderInternal`,
//  because nothing composed `key + timestamp`. These tests pin the
//  composition down as the exact inverse of the engine's
//  `BEEPING_ParseScheduledPayload`.
//
//  The canonical spec comes from `BEEPING_EncodeWithSchedule` in
//  `BeepingCoreLib_api.h`: the payload is "`code` concatenated with the
//  rounded timestamp of the beep in seconds, encoded as 4-char zero-padded
//  base-32 (alphabet [0-9a-v])", where `code` is the 5-char key.
//

import Testing

@testable import Beeping

private func payload(
    key: String,
    decodedString: String? = nil,
    timestamp: Int = 0
) -> BeepingPayload {
    BeepingPayload(
        key: key,
        decodedString: decodedString ?? key,
        mode: 0,
        timestamp: timestamp,
        confidence: 1.0,
        confidenceError: 0,
        confidenceNoise: 0,
        receivedBeepsVolume: 0)
}

@Suite("LocalEncoder wire format (BEE-2355)")
struct LocalEncoderWireFormatTests {

    @Test("A 5-char key composes to 9 chars, key first")
    func composesKeyAndTimestamp() throws {
        let wire = try LocalEncoder.wireString(for: payload(key: "beep1"))
        #expect(wire.count == 9)
        #expect(wire.hasPrefix("beep1"))
        #expect(wire == "beep10000", "timestamp 0 is the zero-padded tag 0000")
    }

    @Test("The timestamp tag is 4-char zero-padded base-32")
    func timestampTagIsBase32() throws {
        // 1 → "0001"; 31 → "000v" ('v' is symbol 31); 32 → "0010".
        #expect(try LocalEncoder.wireString(for: payload(key: "00000", timestamp: 1)) == "000000001")
        #expect(try LocalEncoder.wireString(for: payload(key: "00000", timestamp: 31)) == "00000000v")
        #expect(try LocalEncoder.wireString(for: payload(key: "00000", timestamp: 32)) == "000000010")
    }

    @Test("The tag stays 4 chars at and beyond the 32^4 boundary")
    func timestampWrapsWithoutGrowing() throws {
        // 32^4 - 1 is the largest representable value: "vvvv".
        #expect(try LocalEncoder.wireString(for: payload(key: "abcde", timestamp: 1_048_575)) == "abcdevvvv")
        // 32^4 wraps back to 0 rather than producing a 5-char tag.
        let wrapped = try LocalEncoder.wireString(for: payload(key: "abcde", timestamp: 1_048_576))
        #expect(wrapped == "abcde0000")
        #expect(wrapped.count == 9)
    }

    @Test("Negative timestamps clamp to zero instead of wrapping far ahead")
    func negativeTimestampClamps() throws {
        #expect(try LocalEncoder.wireString(for: payload(key: "abcde", timestamp: -5)) == "abcde0000")
    }

    @Test("Keys of the wrong length are rejected")
    func rejectsWrongLength() {
        for bad in ["", "abcd", "abcdef", "abcde0000"] {
            #expect(throws: BeepingError.self) {
                try LocalEncoder.wireString(for: payload(key: bad))
            }
        }
    }

    @Test("Keys outside the base-32 alphabet are rejected")
    func rejectsNonBase32() {
        // 'w'..'z' are outside GF(2^5); uppercase is refused even though the
        // C engine would accept it, because the published API is lowercase.
        for bad in ["beepw", "beepz", "BEEP1", "bee p", "beep!"] {
            #expect(throws: BeepingError.self) {
                try LocalEncoder.wireString(for: payload(key: bad))
            }
        }
    }

    @Test("`BEEP1` — the old example default — fails on case, not on length")
    func beep1FailsOnCaseNotLength() {
        #expect(BeepingError.self != nil)
        do {
            _ = try LocalEncoder.wireString(for: payload(key: "BEEP1"))
            Issue.record("expected uppercase to be rejected")
        } catch let error as BeepingError {
            guard case .decoderInternal(let reason) = error else {
                Issue.record("expected decoderInternal, got \(error)")
                return
            }
            #expect(
                reason.contains("base32") || reason.contains("alphabet"),
                "the reason must name the alphabet, not the length: \(reason)")
        } catch {
            Issue.record("unexpected error \(error)")
        }
    }

    @Test("An already-composed payload with an empty key falls back to its prefix")
    func emptyKeyFallsBackToPrefix() throws {
        let p = payload(key: "", decodedString: "beep10000")
        #expect(try LocalEncoder.wireString(for: p) == "beep10000")
    }

    @Test("Composition round-trips through the engine's own parser")
    func roundTripsThroughEngineParser() throws {
        let wire = try LocalEncoder.wireString(for: payload(key: "a1b2c", timestamp: 4242))
        let parsed = try #require(BeepingCoreWrapper.parseScheduledPayload(wire))
        #expect(parsed.code == "a1b2c")
        #expect(parsed.timestampSec == 4242)
    }
}
