//
//  TelemetryHook.swift
//  Beeping
//
//  Public protocol for consumers to inject their own telemetry sink
//  (Sentry, Firebase Analytics, Datadog, plain `os.Logger`, etc.). The
//  SDK calls `record(_:)` on the hook only when **all of**:
//
//    1. The consumer set `.telemetryEnabled(true)` on the builder.
//    2. The consumer set a `.telemetryHook(_:)` on the builder.
//
//  Both default to off / nil: the SDK ships zero telemetry by default.
//

import Foundation

/// Receives `TelemetryEvent`s emitted by the SDK. Implementations should
/// forward to their backend of choice (or no-op).
///
/// The method is `async` so the hook can perform network I/O without
/// blocking the SDK's actor. **Errors thrown from `record(_:)` are
/// swallowed by the SDK** — telemetry must never break the consumer's
/// audio session.
public protocol TelemetryHook: Sendable {
    /// Records one event. SDK guarantees: this is called only when
    /// telemetry is opted in, and never with PII in the event payload.
    func record(_ event: TelemetryEvent) async
}
