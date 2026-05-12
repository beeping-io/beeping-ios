//
//  TelemetryClient.swift
//  Beeping
//
//  Internal actor that gates telemetry routing. `BeepingClient` calls
//  `record(_:)` on this actor at lifecycle moments; the actor decides
//  (based on the opt-in flag + hook presence) whether to forward to
//  the consumer-provided hook.
//
//  ## Privacy guarantees (BEE-75)
//
//  - The actor's `record(_:)` is a no-op when `enabled == false`.
//    Even if a hook is set, no event is forwarded.
//  - Events carry only metrics (`TelemetryEvent` cases) — no PII per
//    type definition.
//  - Hook errors are swallowed: the SDK never lets a broken hook
//    propagate failures into the consumer's audio path.
//

import Foundation

internal actor TelemetryClient {

    // MARK: - State

    private let enabled: Bool
    private let hook: (any TelemetryHook)?

    // MARK: - Init

    /// - Parameters:
    ///   - enabled: from `BeepingClientBuilder.telemetryEnabled(_:)`.
    ///     Default `false` (privacy-first per `docs/PRODUCTO.md` §9).
    ///   - hook: optional sink from
    ///     `BeepingClientBuilder.telemetryHook(_:)`. If nil, recording
    ///     is a no-op even when `enabled == true`.
    internal init(enabled: Bool, hook: (any TelemetryHook)?) {
        self.enabled = enabled
        self.hook = hook
    }

    // MARK: - Recording

    /// Forwards `event` to the configured hook iff opted in. Swallows
    /// any error thrown by the hook to keep telemetry off the
    /// consumer's critical path.
    internal func record(_ event: TelemetryEvent) async {
        guard enabled, let hook else { return }
        await hook.record(event)
    }

    // MARK: - Test accessors

    /// Visible to `@testable import Beeping` so privacy tests can assert
    /// the gate's state without exposing it publicly.
    internal var isEnabled: Bool { enabled }

    /// Visible to tests; the optional `any TelemetryHook` itself stays
    /// behind the gate.
    internal var hasHook: Bool { hook != nil }
}
