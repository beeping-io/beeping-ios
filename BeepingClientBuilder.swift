//
//  BeepingClientBuilder.swift
//  Beeping
//
//  Fluent builder for `BeepingClient`. Constructed via the static
//  factory methods on `BeepingClient` (`.local()` / `.cloud(...)`),
//  configured with chained methods, finalized with `.build()`.
//
//  Why a builder over plain factory args? The configuration surface
//  grows over the lifetime of Phase 9 (BEE-74 logging, BEE-75 telemetry,
//  potentially more). A builder keeps the public init signature tight
//  while letting consumers opt into knobs they care about.
//
//  ```swift
//  let client = BeepingClient.local()
//      .mode(.audible)
//      .logLevel(.debug)         // BEE-74 will wire this up
//      .telemetryEnabled(true)   // BEE-75 will wire this up
//      .build()
//
//  let cloud = BeepingClient
//      .cloud(apiKey: "k", endpoint: URL(string: "https://api.beeping.io")!)
//      .build()
//  ```
//

import Foundation

public struct BeepingClientBuilder: Sendable {

    // MARK: - Stored config (immutable after `build()`)

    private let encoderFactory: @Sendable () -> any BeepingEncoder
    private var mode: BeepingMode = .all
    private var logLevel: BeepingLogLevel = .info
    private var telemetryEnabled: Bool = false

    // MARK: - Init (internal — constructed via factory methods on BeepingClient)

    internal init(encoderFactory: @escaping @Sendable () -> any BeepingEncoder) {
        self.encoderFactory = encoderFactory
    }

    // MARK: - Fluent setters

    /// Decoder mode. Default `.all` — matches any audible / non-audible
    /// / hidden tone. Restrict to a single mode for performance or
    /// privacy reasons.
    public func mode(_ mode: BeepingMode) -> Self {
        var copy = self
        copy.mode = mode
        return copy
    }

    /// Log verbosity. Stored on the actor; the actual `os.Logger`
    /// wiring lands in BEE-74. Setting this in BEE-72 is forward-compat.
    public func logLevel(_ level: BeepingLogLevel) -> Self {
        var copy = self
        copy.logLevel = level
        return copy
    }

    /// Whether the telemetry hook is opted in. Stored on the actor; the
    /// actual hook wiring lands in BEE-75. Default `false` —
    /// privacy-first per `docs/PRODUCTO.md` section 9.
    public func telemetryEnabled(_ enabled: Bool) -> Self {
        var copy = self
        copy.telemetryEnabled = enabled
        return copy
    }

    // MARK: - Build

    /// Constructs a `BeepingClient` with the accumulated config.
    public func build() -> BeepingClient {
        BeepingClient(
            encoder: encoderFactory(),
            mode: mode,
            logLevel: logLevel,
            telemetryEnabled: telemetryEnabled
        )
    }
}
