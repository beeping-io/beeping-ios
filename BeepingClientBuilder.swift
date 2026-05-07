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

    /// Factory receives the configured `BeepingCoreWrapper` (so local-mode
    /// encoders can share the same engine handle the listener uses) and
    /// the resolved `BeepingMode` (so cloud encoders can include it in
    /// the wire request — server default is `.inaudible`, which most
    /// laptop speakers can't reproduce). Wrapper is ignored by
    /// cloud-mode encoders; mode is ignored by local-mode encoders since
    /// it's already baked into the wrapper via `configure(mode:)`.
    private let encoderFactory: @Sendable (BeepingCoreWrapper, BeepingMode) -> any BeepingEncoder
    private var mode: BeepingMode = .all
    private var logLevel: BeepingLogLevel = .info
    private var telemetryEnabled: Bool = false
    private var telemetryHook: (any TelemetryHook)?

    // MARK: - Init (internal — constructed via factory methods on BeepingClient)

    internal init(
        encoderFactory: @escaping @Sendable (BeepingCoreWrapper, BeepingMode) -> any BeepingEncoder
    ) {
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

    /// Whether the telemetry hook is opted in. Default `false` —
    /// privacy-first per `docs/PRODUCTO.md` section 9. Wired up in
    /// BEE-75: when this is `true` AND a hook is set via
    /// `.telemetryHook(_:)`, the SDK forwards typed metrics-only events
    /// to the hook.
    public func telemetryEnabled(_ enabled: Bool) -> Self {
        var copy = self
        copy.telemetryEnabled = enabled
        return copy
    }

    /// Sets the consumer-provided `TelemetryHook` sink (Sentry, Firebase,
    /// Datadog, custom). If `nil` (default), the SDK never forwards
    /// telemetry even when `telemetryEnabled(true)`. Per BEE-75 the hook
    /// must conform to `Sendable` and is called from an internal actor
    /// — implementations don't need to be main-thread-safe themselves.
    public func telemetryHook(_ hook: (any TelemetryHook)?) -> Self {
        var copy = self
        copy.telemetryHook = hook
        return copy
    }

    // MARK: - Build

    /// Constructs a `BeepingClient` with the accumulated config. Creates and
    /// configures the wrapper here so the encoder factory can attach to the
    /// same engine handle (critical for `LocalEncoder`, which would crash
    /// against an unconfigured handle in `BEEPING_EncodeDataToAudioBuffer`).
    public func build() -> BeepingClient {
        let wrapper = BeepingCoreWrapper(logLevel: logLevel)
        wrapper.configure(mode: mode)
        let encoder = encoderFactory(wrapper, mode)
        return BeepingClient(
            wrapper: wrapper,
            encoder: encoder,
            mode: mode,
            logLevel: logLevel,
            telemetryEnabled: telemetryEnabled,
            telemetryHook: telemetryHook
        )
    }
}
