//
//  BeepingError.swift
//  Beeping
//
//  Internal error model. The public surface lands in BEE-71 (strategy
//  pattern) and BEE-72 (builder DSL); during BEE-68 we only keep the type
//  defined for the Swift internal layer to consume — legacy ObjC paths
//  (Beeping.m, BeepingCore.m, IosAudioController.m) still surface failures
//  via NSLog and OSStatus, untouched.
//

import Foundation

/// Errors surfaced by the SDK. `Sendable` so the actor-based API
/// (`BeepingClient`, BEE-70) can pass values across isolation domains
/// without `@unchecked`. Promoted from `internal` to `public` in BEE-70
/// because it appears in the public `BeepingClient.Event.failed(_:)`
/// case payload.
public enum BeepingError: Error, Sendable, Equatable {
    /// `AVAudioSession` couldn't be activated — typically because the user
    /// denied microphone access or the session was claimed by another app.
    case missingMicrophonePermission

    /// The audio session was interrupted (incoming call, Siri, another
    /// foreground app starting playback). Recoverable: the caller waits
    /// for the interruption to end and restarts `listen()`.
    case audioSessionInterrupted

    /// `libBeepingCoreUniversal.a` failed to load (or post-BEE-79 the
    /// XCFramework binary target failed to resolve). Not recoverable from
    /// the SDK side — the app bundle is malformed.
    case nativeLibraryNotLoaded

    /// The decoder reported a non-recoverable internal failure. Carries a
    /// human-readable reason for diagnostics; not part of any public
    /// contract. Reserved for **real decoder/encoder failures** — HTTP
    /// transport failures map to the typed cases below (BEE-2308), never
    /// here.
    case decoderInternal(reason: String)

    /// A cloud request failed at the HTTP/transport layer (BEE-2308).
    /// `statusCode` carries the server's HTTP status when one was received
    /// (e.g. 400 validation, 500 server error); it is `nil` for transport
    /// failures that never reached a response (timeout, DNS, connection
    /// reset, non-HTTP response). Mirrors the Android `NetworkError`
    /// variant for `beeping_flutter` parity (BEE-86).
    case networkError(statusCode: Int?)

    /// A cloud request was rejected for authentication reasons — the API
    /// key is missing, malformed, or unauthorized. Maps HTTP **401/403**
    /// (BEE-2308).
    case authenticationFailed

    /// A cloud request was throttled by the server. Maps HTTP **429**,
    /// carrying the `Retry-After` delay (seconds) parsed from the response
    /// header — `0` when the header is absent or unparseable (BEE-2308).
    case rateLimited(retryAfter: TimeInterval)

    /// The scheduler (`computeBeepSchedule` / `encodeWithSchedule`) rejected
    /// the input or could not produce a buffer. Carries the raw C return
    /// code plus a human-readable reason for diagnostics.
    case schedulerError(code: Int32, reason: String)

    /// `sendScheduled(...)` was called on a cloud-mode client. Scheduled
    /// emission encodes + plays locally via the C engine; cloud mode
    /// delegates encoding to the server, which has no scheduled endpoint.
    /// Mirrors the Android `SchedulingNotSupported` variant for
    /// `beeping_flutter` parity (BEE-2329 / BEE-86).
    case schedulingNotSupported
}
