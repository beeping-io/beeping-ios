//
//  BeepingClient.swift
//  Beeping
//
//  Modern public API for Beeping. Actor-based, instance-based,
//  AsyncStream-driven. Replaces the legacy `Beeping` ObjC singleton + its
//  delegate protocol on the Swift side; the legacy class persists for
//  ObjC consumers until the eventual deprecation in 1.0.
//
//  ## Concurrency
//
//  `BeepingClient` is an `actor` — every public method serializes through
//  the actor executor. The internal `BeepingCoreWrapper` is non-isolated
//  and surfaces audio-token events on its own serial dispatch queue;
//  this actor hops those events into its own isolation domain via
//  `Task { await self.dispatch(...) }` before yielding to consumer
//  AsyncStream continuations.
//
//  ## Multi-listener
//
//  Each `listen()` call creates a fresh `AsyncStream<Event>`. Multiple
//  listeners receive identical event sequences; the actor fan-outs by
//  yielding to all registered continuations. `close()` terminates them
//  all.
//
//  ## Scope of BEE-70
//
//  This task introduces the actor surface. The `.local()` / `.cloud(...)`
//  factory methods land in BEE-72. Cloud-mode HTTP transport lands in
//  BEE-73 (swift-openapi-generator). The strategy pattern that switches
//  encode/decode between local C++ engine and cloud HTTP lands in
//  BEE-71. Until then, `send(_:)` emits locally (encode + play).
//

import Foundation

/// Public entry point for the Beeping SDK. Instance-based and actor-isolated.
///
/// ```swift
/// let client = BeepingClient(mode: .all)
/// let stream = await client.listen()
/// for await event in stream {
///     switch event {
///     case .started:                 break
///     case .decoded(let payload):    handle(payload)
///     case .failed(let reason):      handle(reason)
///     case .stopped:                 break
///     }
/// }
/// await client.close()
/// ```
public actor BeepingClient {

    // MARK: - Event

    /// Discrete events surfaced through `listen()`'s AsyncStream.
    ///
    /// `Sendable` because every associated value is itself `Sendable`
    /// (`BeepingPayload` struct, `BeepingError` enum). The new event type
    /// lives nested here to coexist with the legacy top-level
    /// `BeepingEvent` ObjC class; consumer code rarely names it
    /// explicitly (`for await event in stream` infers it).
    public enum Event: Sendable, Equatable {
        /// The audio session is up and the decoder is listening. Emitted
        /// once per `listen()` cycle.
        case started

        /// A beep with valid decoded data was received.
        case decoded(BeepingPayload)

        /// An error occurred. Recoverable errors (network, audio session
        /// interruption) may be followed by further events; fatal errors
        /// (native library not loaded) are typically followed by `.stopped`.
        case failed(BeepingError)

        /// The session was closed (either by `close()` or by an
        /// unrecoverable internal failure).
        case stopped
    }

    // MARK: - State

    private let wrapper: BeepingCoreWrapper
    private let encoder: any BeepingEncoder
    private var streams: [UUID: AsyncStream<Event>.Continuation] = [:]

    // BEE-72: builder-set knobs. BEE-74 wired up logLevel, BEE-75 wires
    // up telemetry. They are stored here so internal components can
    // read them and so tests can verify (via @testable import) that the
    // builder's settings reached the actor.
    internal let logLevel: BeepingLogLevel
    internal let telemetryEnabled: Bool
    internal let telemetryClient: TelemetryClient

    /// Decoder mode this client was constructed with. Captured for
    /// telemetry's `sessionStarted(mode:)` event.
    private let modeForTelemetry: BeepingMode

    // MARK: - Init

    /// Creates a new client configured to decode the given mode. The
    /// default encoder is `LocalEncoder` (on-device C++ via ObjC++).
    /// To pick a different strategy (e.g. cloud), construct via the
    /// public factory methods in BEE-72 or pass an explicit encoder
    /// to the internal initializer below.
    ///
    /// - Parameter mode: which carrier to decode. Default `.all` matches
    ///   any audible / non-audible / hidden tone. Other values let you
    ///   restrict decoding for performance or privacy reasons.
    public init(mode: BeepingMode = .all) {
        let w = BeepingCoreWrapper(logLevel: .info)
        self.wrapper = w
        self.encoder = LocalEncoder(wrapper: w)
        self.logLevel = .info
        self.telemetryEnabled = false
        self.telemetryClient = TelemetryClient(enabled: false, hook: nil)
        self.modeForTelemetry = mode
        w.configure(mode: mode)
        Self.wireEvents(
            wrapper: w,
            dispatch: { [weak self] legacy in
                Task { [weak self] in await self?.dispatch(legacyEvent: legacy) }
            })
    }

    /// Internal initializer that lets the caller pick the encoder
    /// strategy and the builder-set knobs. Used by `BeepingClientBuilder`
    /// (BEE-72) and by tests that want to inject a stub encoder. The
    /// decode path (mic capture) is always local — only the encode
    /// strategy is configurable here.
    ///
    /// The two-arg variant lets the builder share its already-configured
    /// `BeepingCoreWrapper` between encode and decode paths. The
    /// single-arg variant constructs and configures a fresh wrapper for
    /// callers that don't supply one (kept for source compatibility with
    /// pre-fix usages and existing tests).
    internal init(
        encoder: any BeepingEncoder,
        mode: BeepingMode = .all,
        logLevel: BeepingLogLevel = .info,
        telemetryEnabled: Bool = false,
        telemetryHook: (any TelemetryHook)? = nil
    ) {
        let w = BeepingCoreWrapper(logLevel: logLevel)
        w.configure(mode: mode)
        self.init(
            wrapper: w,
            encoder: encoder,
            mode: mode,
            logLevel: logLevel,
            telemetryEnabled: telemetryEnabled,
            telemetryHook: telemetryHook
        )
    }

    /// Init used by `BeepingClientBuilder.build()` so the local encoder and
    /// the listener share the same configured wrapper.
    internal init(
        wrapper: BeepingCoreWrapper,
        encoder: any BeepingEncoder,
        mode: BeepingMode,
        logLevel: BeepingLogLevel,
        telemetryEnabled: Bool,
        telemetryHook: (any TelemetryHook)?
    ) {
        self.wrapper = wrapper
        self.encoder = encoder
        self.logLevel = logLevel
        self.telemetryEnabled = telemetryEnabled
        self.telemetryClient = TelemetryClient(enabled: telemetryEnabled, hook: telemetryHook)
        self.modeForTelemetry = mode
        Self.wireEvents(
            wrapper: wrapper,
            dispatch: { [weak self] legacy in
                Task { [weak self] in await self?.dispatch(legacyEvent: legacy) }
            })
    }

    // MARK: - Public factory methods (BEE-72)

    /// Returns a builder configured to emit through the **on-device**
    /// encoder (the C++ engine via the ObjC++ bridge — `LocalEncoder`).
    /// Default mode is `.all`; chain `.mode(_:)` to restrict.
    ///
    /// ```swift
    /// let client = BeepingClient.local().build()
    /// ```
    public static func local() -> BeepingClientBuilder {
        BeepingClientBuilder(encoderFactory: { wrapper, _ in LocalEncoder(wrapper: wrapper) })
    }

    /// Returns a builder configured to emit through the **cloud**
    /// encoder (URLSession to `beepbox-server` — `CloudEncoder`).
    /// Default mode is `.all`.
    ///
    /// ```swift
    /// let client = BeepingClient
    ///     .cloud(apiKey: "your-key", endpoint: URL(string: "https://api.beeping.io")!)
    ///     .build()
    /// ```
    ///
    /// - Parameters:
    ///   - apiKey: server-issued API key (sent as `X-API-Key` header).
    ///   - endpoint: base URL of the `beepbox-server` instance.
    public static func cloud(apiKey: String, endpoint: URL) -> BeepingClientBuilder {
        BeepingClientBuilder(encoderFactory: { wrapper, mode in
            CloudEncoder(
                apiKey: apiKey, endpoint: endpoint,
                mode: mode, loopbackWrapper: wrapper)
        })
    }

    /// Helper to factor out the closure boilerplate used by both inits.
    /// The `dispatch` closure is invoked from the wrapper's serial
    /// dispatch queue; it must hop back to the actor itself.
    private static func wireEvents(
        wrapper: BeepingCoreWrapper,
        dispatch: @escaping @Sendable (BeepingEvent) -> Void
    ) {
        wrapper.onEvent = { legacyEvent in
            dispatch(legacyEvent)
        }
    }

    // MARK: - Public API

    /// Starts listening and returns an `AsyncStream` of events.
    ///
    /// Calling `listen()` multiple times creates independent streams.
    /// Each stream receives the full event sequence; closing the actor
    /// (`close()`) terminates all of them.
    ///
    /// The stream's iterator can be cancelled by breaking out of the
    /// `for await` loop or by tearing down the consumer Task; the actor
    /// removes the corresponding continuation when its `onTermination`
    /// fires.
    ///
    /// - Returns: an `AsyncStream<Event>` that yields events until `close()`.
    public func listen() -> AsyncStream<Event> {
        AsyncStream { continuation in
            let id = UUID()
            self.streams[id] = continuation
            self.wrapper.startListening()

            // BEE-75: emit sessionStarted to telemetry. The actor
            // serializes; the await is fire-and-forget via Task.
            let mode = self.modeForTelemetry
            Task { [weak self] in
                await self?.telemetryClient.record(.sessionStarted(mode: mode))
            }

            continuation.onTermination = { [weak self] _ in
                Task { [weak self] in
                    await self?.removeStream(id: id)
                }
            }
        }
    }

    /// Encodes and emits a payload through whichever encoder strategy
    /// this client was constructed with (BEE-71). The default encoder is
    /// `LocalEncoder` (on-device C++ via ObjC++). Cloud-mode encoders
    /// (URLSession to `beepbox-server`) become available via the public
    /// factory methods in BEE-72.
    ///
    /// - Parameter payload: the payload to transmit. Only `decodedString`
    ///   is used by the encoder; other fields are metadata that the
    ///   receiving end will reconstruct on decode.
    /// - Throws: `BeepingError` from the encoder strategy
    ///   (network / auth / decoder failures, depending on mode).
    public func send(_ payload: BeepingPayload) async throws {
        try await encoder.encode(payload)
        await telemetryClient.record(.beepEmitted)
    }

    /// Compute the wall-clock timestamps (in seconds) at which beeps fire
    /// when emitting `code` repeatedly across a fixed-duration schedule.
    ///
    /// Pure math — does not touch the audio engine. Use this to drive a
    /// UI preview of the schedule, or to feed a custom mixer that wants
    /// to start each beep at the canonical timestamps without calling
    /// `encodeWithSchedule(...)`.
    ///
    /// - Parameters:
    ///   - duration: Total schedule duration in seconds. Must be `>= 2.3`.
    ///   - startTime: Offset of the first beep in seconds. Must be `>= 0`
    ///     and `startTime + 2.3 <= duration`.
    ///   - interval: Seconds between successive beeps. Must be `> 0`.
    /// - Returns: Sorted ascending timestamps in seconds, one per beep.
    /// - Throws: `BeepingError.schedulerError` with the underlying C
    ///   return code if any parameter is out of range.
    public nonisolated static func computeBeepSchedule(
        duration: TimeInterval,
        startTime: TimeInterval,
        interval: TimeInterval
    ) throws -> [TimeInterval] {
        try BeepingCoreWrapper.computeBeepSchedule(
            duration: Float(duration),
            startTime: Float(startTime),
            interval: Float(interval))
    }

    /// Encode `code` as multiple beeps scheduled across `duration` seconds
    /// and return the resulting float32 mono PCM samples at 44100 Hz.
    ///
    /// Each beep's payload is `code` concatenated with the rounded
    /// timestamp of the beep (4-char zero-padded base-32) — the decoder
    /// can recover the beep's position via `BeepingPayload.timestamp`.
    /// Silence between beeps is written as zeros, so the returned buffer
    /// is exactly `floor(duration * 44100)` samples long.
    ///
    /// Runs the C engine on the actor's executor — fast for short
    /// durations (<30 s) but still async since the buffer may be tens of
    /// MB for long schedules.
    ///
    /// - Parameters:
    ///   - code: Payload to repeat (typically a 5-char base-32 key).
    ///   - duration: Total duration in seconds. Must be `>= 2.3`.
    ///   - startTime: Offset of the first beep in seconds. Must be `>= 0`.
    ///   - interval: Seconds between beeps. Must be `> 0`.
    ///   - beepGainDb: Beep volume in dB. Clamped internally to `[-60, +12]`.
    /// - Returns: float32 mono PCM samples at 44100 Hz.
    /// - Throws: `BeepingError.schedulerError` if the C engine rejects
    ///   the input or runs out of buffer space.
    public func encodeWithSchedule(
        code: String,
        duration: TimeInterval,
        startTime: TimeInterval,
        interval: TimeInterval,
        beepGainDb: Float = 0
    ) async throws -> Data {
        try wrapper.encodeWithSchedule(
            code: code,
            duration: Float(duration),
            startTime: Float(startTime),
            interval: Float(interval),
            beepGainDb: beepGainDb)
    }

    /// Stops listening, terminates all `listen()` streams, and tears
    /// down the audio session.
    ///
    /// Safe to call multiple times; idempotent.
    public func close() async {
        wrapper.stopListening()
        for continuation in streams.values {
            continuation.yield(.stopped)
            continuation.finish()
        }
        streams.removeAll()
        await telemetryClient.record(.sessionStopped)
    }

    // MARK: - Private

    private func dispatch(legacyEvent: BeepingEvent) {
        let event = Self.convert(legacy: legacyEvent)
        for continuation in streams.values {
            continuation.yield(event)
        }
        // BEE-75: emit telemetry for the converted event. Privacy-safe:
        // only metrics + category propagate, never decoded data.
        Task { [weak self] in
            await self?.recordTelemetry(for: event)
        }
    }

    private func recordTelemetry(for event: Event) async {
        switch event {
        case .decoded(let payload):
            await telemetryClient.record(
                .beepDecoded(confidence: payload.confidence, mode: payload.mode)
            )
        case .failed:
            await telemetryClient.record(.errorOccurred(category: .decoder))
        case .started, .stopped:
            // .started has its own emission in `listen()` so we don't
            // double-record here. .stopped is recorded in `close()`.
            break
        }
    }

    private func removeStream(id: UUID) {
        streams.removeValue(forKey: id)
    }

    private static func convert(legacy: BeepingEvent) -> Event {
        switch legacy.status {
        case .start:
            return .started
        case .endOk:
            guard let key = legacy.key, let decoded = legacy.decodedString else {
                return .failed(.decoderInternal(reason: "endOk emitted without key/decodedString"))
            }
            let payload = BeepingPayload(
                key: key,
                decodedString: decoded,
                mode: legacy.mode,
                timestamp: legacy.timestamp,
                confidence: legacy.confidence,
                confidenceError: legacy.confidenceError,
                confidenceNoise: legacy.confidenceNoise,
                receivedBeepsVolume: legacy.receivedBeepsVolume
            )
            return .decoded(payload)
        case .endBad:
            return .failed(.decoderInternal(reason: "endBad: decoded data invalid"))
        @unknown default:
            return .failed(.decoderInternal(reason: "unknown legacy status: \(legacy.status.rawValue)"))
        }
    }
}
