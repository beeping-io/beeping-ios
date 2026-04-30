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
    private var streams: [UUID: AsyncStream<Event>.Continuation] = [:]

    // MARK: - Init

    /// Creates a new client configured to decode the given mode.
    ///
    /// - Parameter mode: which carrier to decode. Default `.all` matches
    ///   any audible / non-audible / hidden tone. Other values let you
    ///   restrict decoding for performance or privacy reasons.
    public init(mode: BeepingMode = .all) {
        let w = BeepingCoreWrapper()
        self.wrapper = w
        w.configure(mode: mode)

        // Wire wrapper -> actor. Runs on wrapper's serial dispatch queue;
        // hop into the actor before touching `streams`.
        w.onEvent = { [weak self] legacyEvent in
            guard let self else { return }
            Task { [weak self] in
                await self?.dispatch(legacyEvent: legacyEvent)
            }
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

            continuation.onTermination = { [weak self] _ in
                Task { [weak self] in
                    await self?.removeStream(id: id)
                }
            }
        }
    }

    /// Encodes and emits a payload through the device speaker.
    ///
    /// In BEE-70 this is a thin wrapper over the local encoder + audio
    /// engine. The cloud-mode strategy (route encoding through
    /// `beepbox-server`) lands in BEE-71. The function signature already
    /// throws so future implementations can surface network / auth errors.
    ///
    /// - Parameter payload: the payload to transmit. Only `decodedString`
    ///   is used by the encoder; other fields are metadata that the
    ///   receiving end will reconstruct on decode.
    public func send(_ payload: BeepingPayload) async throws {
        wrapper.play(code: payload.decodedString)
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
    }

    // MARK: - Private

    private func dispatch(legacyEvent: BeepingEvent) {
        let event = Self.convert(legacy: legacyEvent)
        for continuation in streams.values {
            continuation.yield(event)
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
