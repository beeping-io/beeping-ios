//
//  TelemetryTests.swift
//  BeepingTests
//
//  Privacy-first tests for BEE-75: confirm the SDK NEVER forwards events
//  to a hook unless the consumer explicitly opted in, and that even when
//  opted in, the events carry only metrics — no PII.
//

import Testing
import Foundation
@testable import Beeping

// MARK: - Test doubles

/// Captures every event passed to `record(_:)`. Used to assert the
/// privacy gate (no events when opt-out) and the opt-in flow (events
/// flow correctly).
private actor SpyTelemetryHook: TelemetryHook {
    private(set) var captured: [TelemetryEvent] = []

    func record(_ event: TelemetryEvent) async {
        captured.append(event)
    }

    func snapshot() -> [TelemetryEvent] { captured }
}

/// Always throws (well, returns) without recording. Used to verify the
/// SDK swallows hook errors so a broken hook never breaks the audio path.
private actor ExplodingHook: TelemetryHook {
    nonisolated(unsafe) static var calls = 0
    func record(_ event: TelemetryEvent) async {
        Self.calls += 1
        // The protocol isn't `async throws` so we can't actually throw,
        // but a hook that hangs forever would be just as bad. Smoke
        // test: we reach this method, it returns, the SDK keeps going.
    }
}

@Suite("Telemetry privacy gate (BEE-75)")
struct TelemetryTests {

    // MARK: - Privacy gate: opt-out by default

    @Test("Default builder sets telemetryEnabled=false (privacy-first)")
    func defaultIsOptOut() async {
        let client = BeepingClient.local().build()
        let enabled = await client.telemetryEnabled
        #expect(enabled == false)
        await client.close()
    }

    @Test("With telemetryEnabled=false + hook set, NO events reach the hook")
    func privacyGate_disabledNoEmissions() async throws {
        let spy = SpyTelemetryHook()
        let client = BeepingClient.local()
            .telemetryEnabled(false)        // explicitly opt-out
            .telemetryHook(spy)             // hook IS set, but should be ignored
            .build()

        // Trigger lifecycle events that would normally emit telemetry.
        let stream = await client.listen()
        // Schedule close so the listen stream terminates.
        Task { try? await Task.sleep(for: .milliseconds(50)); await client.close() }
        for await _ in stream { /* drain */ }

        // Allow any pending Task to finish.
        try await Task.sleep(for: .milliseconds(100))

        let captured = await spy.snapshot()
        #expect(captured.isEmpty, "Expected zero telemetry events with opt-out, got \(captured.count)")
    }

    @Test("With telemetryEnabled=false + NO hook, no crash + no emission")
    func privacyGate_disabledNoHookSafe() async {
        let client = BeepingClient.local()
            .telemetryEnabled(false)
            .build()
        await client.close()
        // Reaching here = no crash. There's nothing observable to assert
        // beyond that.
    }

    // MARK: - Opt-in flow

    @Test("With telemetryEnabled=true + hook set, sessionStopped is recorded on close")
    func optIn_sessionStoppedRecorded() async throws {
        let spy = SpyTelemetryHook()
        let client = BeepingClient.local()
            .telemetryEnabled(true)
            .telemetryHook(spy)
            .build()
        await client.close()

        // Allow the close()'s telemetry await to finish.
        try await Task.sleep(for: .milliseconds(100))

        let captured = await spy.snapshot()
        #expect(captured.contains(.sessionStopped))
    }

    @Test("With telemetryEnabled=true but NO hook, no crash + no observable emission")
    func optIn_noHookSafe() async {
        let client = BeepingClient.local()
            .telemetryEnabled(true)
            .build()                          // hook is nil
        await client.close()
    }

    // MARK: - PII: typed events carry only metrics

    @Test("TelemetryEvent.beepDecoded carries only confidence + mode (no decoded data)")
    func eventTypes_noPII() {
        // Compile-time gate: the case has these specific associated
        // values. If anyone adds a `decodedString` parameter, this test
        // fails to compile.
        let evt: TelemetryEvent = .beepDecoded(confidence: 0.8, mode: 2)
        switch evt {
        case .beepDecoded(let confidence, let mode):
            #expect(confidence == 0.8)
            #expect(mode == 2)
        default:
            #expect(Bool(false), "Wrong case")
        }
    }

    @Test("TelemetryEvent.errorOccurred uses ErrorCategory enum (no free-form message)")
    func errorEvent_categoryOnly() {
        let evt: TelemetryEvent = .errorOccurred(category: .decoder)
        switch evt {
        case .errorOccurred(let category):
            #expect(category == .decoder)
        default:
            #expect(Bool(false), "Wrong case")
        }
    }

    @Test("ErrorCategory.allCases covers all expected categories")
    func errorCategories() {
        let cats = TelemetryEvent.ErrorCategory.allCases
        #expect(cats.contains(.audio))
        #expect(cats.contains(.network))
        #expect(cats.contains(.auth))
        #expect(cats.contains(.decoder))
        #expect(cats.contains(.nativeLib))
    }

    // MARK: - Sendable conformance

    @Test("TelemetryEvent + TelemetryHook + TelemetryClient are Sendable")
    func sendableConformance() {
        func requireSendable<T: Sendable>(_ x: T) {}
        requireSendable(TelemetryEvent.sessionStopped)
        requireSendable(TelemetryEvent.errorOccurred(category: .audio))
        // TelemetryHook is a protocol; we verify a conforming type is
        // Sendable. SpyTelemetryHook is an actor, so trivially Sendable.
        requireSendable(SpyTelemetryHook() as any TelemetryHook)
    }

    // MARK: - TelemetryClient direct gate logic

    @Test("TelemetryClient.record is no-op when enabled=false")
    func clientGate_disabled() async {
        let spy = SpyTelemetryHook()
        let client = TelemetryClient(enabled: false, hook: spy)
        await client.record(.sessionStopped)
        let captured = await spy.snapshot()
        #expect(captured.isEmpty)
    }

    @Test("TelemetryClient.record forwards when enabled=true")
    func clientGate_enabled() async {
        let spy = SpyTelemetryHook()
        let client = TelemetryClient(enabled: true, hook: spy)
        await client.record(.sessionStopped)
        let captured = await spy.snapshot()
        #expect(captured == [.sessionStopped])
    }

    @Test("TelemetryClient.record is no-op when hook is nil")
    func clientGate_noHook() async {
        let client = TelemetryClient(enabled: true, hook: nil)
        await client.record(.sessionStopped)
        // No crash = test passes.
    }

    @Test("TelemetryClient exposes its gate state for assertions")
    func clientAccessors() async {
        let spy = SpyTelemetryHook()
        let on = TelemetryClient(enabled: true, hook: spy)
        let off = TelemetryClient(enabled: false, hook: nil)

        let onEnabled = await on.isEnabled
        let onHasHook = await on.hasHook
        let offEnabled = await off.isEnabled
        let offHasHook = await off.hasHook

        #expect(onEnabled == true)
        #expect(onHasHook == true)
        #expect(offEnabled == false)
        #expect(offHasHook == false)
    }
}
