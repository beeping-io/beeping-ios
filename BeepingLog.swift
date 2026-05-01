//
//  BeepingLog.swift
//  Beeping
//
//  Public wrapper over `os.Logger` (Apple's modern logging API since
//  iOS 14). The wrapper adds:
//    - A subsystem-wide trace-ID prefixed to every message, so callers
//      can grep one ID to follow a single SDK session through Console.app
//    - A `BeepingLogLevel` gate so callers can opt in to verbose
//      output without recompiling
//    - Static helpers for redacting PII (API keys + decoded payloads)
//      before they hit the log stream
//
//  Subsystem is fixed at `io.beeping.sdk`. Categories are typed strings
//  passed to each component's logger ("core", "audio", "cloud",
//  "client"). Console.app filters: subsystem == io.beeping.sdk.
//

import Foundation
import os

public struct BeepingLog: Sendable {

    // MARK: - State (immutable post-init)

    private let logger: Logger
    private let level: BeepingLogLevel
    private let category: String
    private let traceID: String

    // MARK: - Init

    /// - Parameters:
    ///   - category: "core" / "audio" / "cloud" / "client" / etc.
    ///   - level: gate; messages below this level are dropped silently.
    ///   - traceID: 8-char identifier shared across the SDK session.
    ///     Default: a fresh random ID. Pass an explicit value to share
    ///     a trace across multiple loggers (e.g. core + audio + cloud
    ///     all use the same trace within one `BeepingClient` session).
    public init(
        category: String,
        level: BeepingLogLevel = .info,
        traceID: String = Self.generateTraceID()
    ) {
        self.logger = Logger(subsystem: "io.beeping.sdk", category: category)
        self.level = level
        self.category = category
        self.traceID = traceID
    }

    // MARK: - Trace-ID

    /// Returns 8 lowercase hex characters from a fresh UUID.
    /// Easy to grep, short enough not to dominate log lines.
    public static func generateTraceID() -> String {
        let raw = UUID().uuidString
        return String(raw.prefix(8)).lowercased()
    }

    // MARK: - Log methods (gated by `level`)

    public func trace(_ message: String) {
        guard level >= .trace else { return }
        // os.Logger has no trace level; map to debug.
        logger.debug("\(self.prefix(), privacy: .public)\(message, privacy: .public)")
    }

    public func debug(_ message: String) {
        guard level >= .debug else { return }
        logger.debug("\(self.prefix(), privacy: .public)\(message, privacy: .public)")
    }

    public func info(_ message: String) {
        guard level >= .info else { return }
        logger.info("\(self.prefix(), privacy: .public)\(message, privacy: .public)")
    }

    public func warn(_ message: String) {
        guard level >= .warn else { return }
        // os.Logger has no warn level; map to notice (the closest).
        logger.notice("\(self.prefix(), privacy: .public)\(message, privacy: .public)")
    }

    public func error(_ message: String) {
        guard level >= .error else { return }
        logger.error("\(self.prefix(), privacy: .public)\(message, privacy: .public)")
    }

    public func fault(_ message: String) {
        guard level >= .fault else { return }
        logger.fault("\(self.prefix(), privacy: .public)\(message, privacy: .public)")
    }

    // MARK: - PII redaction

    /// Masks an API key, preserving its 3-char prefix for diagnostics
    /// (`bk_` prefix is part of `beepbox-server`'s spec) and replacing
    /// the rest with `***`. Use before passing API keys into a log
    /// message, e.g.:
    ///
    ///     log.info("auth=\(BeepingLog.redactAPIKey(apiKey))")
    public static func redactAPIKey(_ key: String) -> String {
        guard key.count > 4 else { return "***" }
        return "\(key.prefix(3))***"
    }

    /// Masks a decoded payload, preserving the first + last char and
    /// replacing the middle with `***`. Use before passing the payload
    /// into a log message at any level above `.debug`.
    public static func redactPayload(_ payload: String) -> String {
        guard payload.count >= 2 else { return "***" }
        let first = payload.prefix(1)
        let last = payload.suffix(1)
        return "\(first)***\(last)"
    }

    // MARK: - Internal accessors (for tests via @testable import)

    /// Effective level gate. Tests use this to assert that a particular
    /// caller-set level produces the expected emission decisions.
    internal var currentLevel: BeepingLogLevel { level }

    /// Trace-ID exposed for tests + for downstream loggers in the same
    /// session that want to share the same ID.
    internal var currentTraceID: String { traceID }

    /// Category exposed for assertions.
    internal var currentCategory: String { category }

    // MARK: - Private

    private func prefix() -> String {
        "[\(traceID)][\(category)] "
    }
}
