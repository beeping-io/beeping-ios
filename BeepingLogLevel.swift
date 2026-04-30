//
//  BeepingLogLevel.swift
//  Beeping
//
//  Placeholder log-level enum exposed through `BeepingClientBuilder`.
//  Stored on the actor but **not yet acted on** in BEE-72 — the wiring
//  to `os.Logger` + the custom logger wrapper + trace-IDs lands in
//  BEE-74. Until then this is a typed value the consumer can express
//  intent with; it doesn't change runtime logging.
//

import Foundation

/// Log verbosity for the Beeping SDK. Maps onto `os.Logger` levels in
/// BEE-74; in BEE-72 it is a builder option only.
public enum BeepingLogLevel: Sendable, Equatable {
    /// Silence the SDK's logger entirely.
    case off

    /// Only fatal / unrecoverable errors.
    case error

    /// Errors + warnings (recoverable / unexpected states).
    case warn

    /// Errors + warnings + lifecycle events. Default.
    case info

    /// Everything, including audio-thread events. Verbose; use only
    /// during development or active troubleshooting.
    case debug
}
