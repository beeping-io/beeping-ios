//
//  BeepingEncoder.swift
//  Beeping
//
//  Internal strategy contract for emitting a payload. Two implementations
//  ship in BEE-71:
//    - `LocalEncoder` (actor) — encodes via the C++ engine and plays
//      through the device speaker (BCNativeCore + AudioEngine path).
//    - `CloudEncoder` (actor) — POSTs the payload to `beepbox-server`
//      via URLSession.
//
//  The protocol is intentionally minimal: a single async-throws method
//  that takes a payload. The concrete strategies own their own state
//  (C handle, URLSession, etc.) and need no further wiring from the
//  caller (`BeepingClient`).
//
//  Public factory methods that pick a strategy from a mode (e.g.
//  `BeepingClient.local()` / `.cloud(apiKey:endpoint:)`) land in BEE-72.
//  The OpenAPI-generated cloud client lands in BEE-73 (CloudEncoder is
//  refactored at that point).
//

import Foundation

internal protocol BeepingEncoder: Sendable {
    /// Emit `payload`. Local strategies play through the speaker; cloud
    /// strategies POST to the configured endpoint. Throws on transport
    /// failures (network, auth, rate limit, encoder internals).
    func encode(_ payload: BeepingPayload) async throws
}
