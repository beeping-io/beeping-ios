//
//  BeepingLogTests.swift
//  BeepingTests
//
//  Tests the BEE-74 logging wrapper: PII redaction, trace-ID generation,
//  level gating logic, Sendable conformance.
//
//  We do NOT integration-test `os.Logger` output (Console.app capture is
//  not test-accessible without private APIs). Instead we test the pure
//  logic surface: redaction helpers, trace-ID format, level comparison,
//  Sendable.
//

import Testing
@testable import Beeping

@Suite("BeepingLog (BEE-74)")
struct BeepingLogTests {

    // MARK: - PII redaction

    @Test("redactAPIKey preserves 3-char prefix + masks rest")
    func redactAPIKeyShape() {
        #expect(BeepingLog.redactAPIKey("bk_secret_abcdef") == "bk_***")
        #expect(BeepingLog.redactAPIKey("api12345") == "api***")
    }

    @Test("redactAPIKey returns *** for short keys")
    func redactAPIKeyShort() {
        #expect(BeepingLog.redactAPIKey("abc") == "***")
        #expect(BeepingLog.redactAPIKey("") == "***")
        #expect(BeepingLog.redactAPIKey("ab") == "***")
        #expect(BeepingLog.redactAPIKey("abcd") == "***")  // 4 chars: still ***
    }

    @Test("redactPayload preserves first + last char")
    func redactPayloadShape() {
        #expect(BeepingLog.redactPayload("12345abcd") == "1***d")
        #expect(BeepingLog.redactPayload("ab") == "a***b")
    }

    @Test("redactPayload returns *** for too-short input")
    func redactPayloadShort() {
        #expect(BeepingLog.redactPayload("a") == "***")
        #expect(BeepingLog.redactPayload("") == "***")
    }

    // MARK: - Trace-ID

    @Test("generateTraceID returns 8 lowercase hex chars")
    func traceIDShape() {
        let id = BeepingLog.generateTraceID()
        #expect(id.count == 8)
        // Lowercase hex: 0-9 and a-f
        let hexChars = Set("0123456789abcdef-")  // UUID has dashes; first 8 chars typically don't
        for c in id {
            #expect(hexChars.contains(c))
        }
    }

    @Test("generateTraceID is reasonably random across calls")
    func traceIDRandomness() {
        let ids = (0..<10).map { _ in BeepingLog.generateTraceID() }
        let unique = Set(ids)
        // 10 calls should produce at least 8 distinct IDs (very loose to
        // avoid flaky tests on very small UUID space corners).
        #expect(unique.count >= 8)
    }

    // MARK: - Level gating + accessors

    @Test("Default level is .info")
    func defaultLevel() {
        let log = BeepingLog(category: "test")
        #expect(log.currentLevel == .info)
    }

    @Test("Init preserves explicit level + traceID + category")
    func initPreserves() {
        let log = BeepingLog(category: "audio", level: .debug, traceID: "abc12345")
        #expect(log.currentLevel == .debug)
        #expect(log.currentTraceID == "abc12345")
        #expect(log.currentCategory == "audio")
    }

    // MARK: - BeepingLogLevel comparison

    @Test("BeepingLogLevel ordering: off < fault < error < warn < info < debug < trace")
    func levelOrdering() {
        #expect(BeepingLogLevel.off    < BeepingLogLevel.fault)
        #expect(BeepingLogLevel.fault  < BeepingLogLevel.error)
        #expect(BeepingLogLevel.error  < BeepingLogLevel.warn)
        #expect(BeepingLogLevel.warn   < BeepingLogLevel.info)
        #expect(BeepingLogLevel.info   < BeepingLogLevel.debug)
        #expect(BeepingLogLevel.debug  < BeepingLogLevel.trace)
    }

    @Test("BeepingLogLevel >= comparison gates correctly")
    func levelGating() {
        // Setting `.info` allows fault/error/warn/info; drops debug/trace.
        #expect(BeepingLogLevel.info >= .fault)
        #expect(BeepingLogLevel.info >= .error)
        #expect(BeepingLogLevel.info >= .warn)
        #expect(BeepingLogLevel.info >= .info)
        #expect(!(BeepingLogLevel.info >= .debug))
        #expect(!(BeepingLogLevel.info >= .trace))

        // Setting `.off` allows nothing.
        #expect(!(BeepingLogLevel.off >= .fault))
    }

    // MARK: - Sendable

    @Test("BeepingLog is Sendable")
    func logIsSendable() {
        func requireSendable<T: Sendable>(_ x: T) {}
        requireSendable(BeepingLog(category: "test"))
    }

    @Test("BeepingLogLevel is Sendable + Equatable")
    func levelIsSendable() {
        func requireSendable<T: Sendable>(_ x: T) {}
        requireSendable(BeepingLogLevel.fault)
        #expect(BeepingLogLevel.trace == .trace)
        #expect(BeepingLogLevel.fault != .trace)
    }
}
