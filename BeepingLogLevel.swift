//
//  BeepingLogLevel.swift
//  Beeping
//
//  Public verbosity level for the SDK's logger. Surfaced through
//  `BeepingClientBuilder.logLevel(_:)` (BEE-72) and consumed by
//  `BeepingLog` (BEE-74) to gate which messages are forwarded to
//  `os.Logger`.
//
//  The `Comparable` conformance enables level checks like
//  `level >= .info` inside the logger's gating logic — the convention
//  is that **higher cases are more verbose**:
//
//      .off  <  .fault  <  .error  <  .warn  <  .info  <  .debug  <  .trace
//
//  So setting `.info` emits info / warn / error / fault messages but
//  drops debug + trace. Setting `.off` emits nothing.
//

import Foundation

public enum BeepingLogLevel: Sendable, Equatable, Comparable {

    /// Silence the SDK's logger entirely.
    case off

    /// Process-fatal failures only (host app would typically crash).
    case fault

    /// Errors / unrecoverable states.
    case error

    /// Warnings — recoverable / unexpected states. Maps to
    /// `os.Logger.notice` (os.Logger has no warn level).
    case warn

    /// Errors + warnings + lifecycle events. **Default** for production.
    case info

    /// Everything except trace; useful during development.
    case debug

    /// Most verbose, including audio-thread events. Use only during
    /// active troubleshooting; `os.Logger` has no trace level so this
    /// maps to `.debug` underneath.
    case trace

    /// Severity ranking used by the `Comparable` conformance.
    /// **Higher index = more verbose**.
    private var severityIndex: Int {
        switch self {
        case .off:    return 0
        case .fault:  return 1
        case .error:  return 2
        case .warn:   return 3
        case .info:   return 4
        case .debug:  return 5
        case .trace:  return 6
        }
    }

    public static func < (lhs: BeepingLogLevel, rhs: BeepingLogLevel) -> Bool {
        lhs.severityIndex < rhs.severityIndex
    }
}
