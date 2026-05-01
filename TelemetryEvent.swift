//
//  TelemetryEvent.swift
//  Beeping
//
//  Typed telemetry events emitted by the SDK. **Privacy-first by
//  construction**: every case carries only metrics (numbers, enums,
//  category strings) — never decoded payloads, API keys, trace-IDs,
//  or any other identifier that could be tied back to a specific
//  end-user.
//
//  Per `docs/PRODUCTO.md` §9 (privacy-first principle): the consumer's
//  chosen sink is the only place these events ever flow, and only when
//  the consumer explicitly opted in via
//  `BeepingClientBuilder.telemetryEnabled(true)`. Default is opt-out.
//

import Foundation

/// Discrete telemetry events surfaced by the SDK to a consumer-provided
/// `TelemetryHook`. All cases are pure metrics — no payload, no auth.
public enum TelemetryEvent: Sendable, Equatable {

    /// Emitted once per `BeepingClient.listen()` cycle. Records which
    /// decoder mode was active.
    case sessionStarted(mode: BeepingMode)

    /// Emitted on `BeepingClient.close()` (or fatal stop).
    case sessionStopped

    /// Emitted when the decoder yields a valid beep. Carries only the
    /// confidence + mode metric — NOT the decoded data.
    case beepDecoded(confidence: Float, mode: Int)

    /// Emitted when the encoder finishes a `send()`. No payload.
    case beepEmitted

    /// Emitted when something failed. Category is a stable string from
    /// `ErrorCategory` for grouping; the underlying error message is
    /// **NOT** included to avoid leaking decoder internals or stack
    /// traces with PII.
    case errorOccurred(category: ErrorCategory)

    /// Stable categories for `errorOccurred`. Add cases as new error
    /// surfaces appear; never log free-form error messages.
    public enum ErrorCategory: String, Sendable, Equatable, CaseIterable {
        case audio       // AVAudioSession / RemoteIO setup or runtime
        case network     // URLSession transport / timeout
        case auth        // 401/403 from beepbox-server
        case decoder     // C engine internal failure / END_BAD
        case nativeLib   // libBeepingCoreUniversal.a load / link issues
    }
}
