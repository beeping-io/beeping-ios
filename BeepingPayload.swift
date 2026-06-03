//
//  BeepingPayload.swift
//  Beeping
//
//  Decoded payload + metadata for a single beep, surfaced through
//  `BeepingClient.Event.decoded(_:)` (BEE-70). Sendable struct, all
//  fields immutable. Replaces the role of the legacy `BeepingEvent` ObjC
//  class for the new actor API; the class persists in parallel for
//  ObjC consumers until the eventual deprecation in 1.0.
//

import Foundation

/// Decoded beep with quality metrics. Use the `key` field for typical
/// "what beep was received" lookups (5-character identifier); inspect
/// `confidence` and `receivedBeepsVolume` to gate downstream actions
/// (e.g. ignore decodes below a confidence threshold).
public struct BeepingPayload: Sendable, Equatable {

    /// 5-character identifier (the "key") extracted from the first 5
    /// characters of `decodedString`. Always non-empty.
    public let key: String

    /// Full 9-character decoded string. Format: 5 chars of key followed by
    /// 4 chars of timestamp encoded in base32 (digits 0-9, letters a-v).
    public let decodedString: String

    /// Decoder mode that matched this beep. Useful when the client was
    /// constructed with `.all` mode and you need to know which sub-mode
    /// the decoder hit. Raw value from the underlying C engine — values
    /// correspond to `BEEPING_MODE_*` (audible, non-audible, hidden).
    public let mode: Int

    /// Decoded timestamp in seconds (4-char base32 from positions 5-8 of
    /// `decodedString`). Encoder convention. 0 if the timestamp was not
    /// part of the encoded payload.
    public let timestamp: Int

    /// Global reception confidence, 0.0..1.0. 1.0 = ideal conditions.
    /// Lower values indicate noisy environment, distant transmitter,
    /// or partial signal.
    public let confidence: Float

    /// Confidence component due to error-correction tokens applied.
    /// Higher = fewer corrections needed.
    public let confidenceError: Float

    /// Confidence component due to signal-to-noise ratio.
    public let confidenceNoise: Float

    /// Average received volume of the beep train, in dB. Closer to 0 is
    /// louder; below ~-90 dB the decoder typically can't recover.
    public let receivedBeepsVolume: Float

    public init(
        key: String,
        decodedString: String,
        mode: Int,
        timestamp: Int,
        confidence: Float,
        confidenceError: Float,
        confidenceNoise: Float,
        receivedBeepsVolume: Float
    ) {
        self.key = key
        self.decodedString = decodedString
        self.mode = mode
        self.timestamp = timestamp
        self.confidence = confidence
        self.confidenceError = confidenceError
        self.confidenceNoise = confidenceNoise
        self.receivedBeepsVolume = receivedBeepsVolume
    }
}

/// A scheduler-encoded payload split into its `code` prefix and the rounded
/// timestamp (seconds) decoded from the trailing 4-char base-32 tag — the
/// inverse of the `code + timestamp` layout `encodeWithSchedule(...)` appends
/// to each beep (BEE-2312).
///
/// Produced by `BeepingClient.parseScheduledPayload(_:)`. The split is
/// performed by the canonical C engine (`BEEPING_ParseScheduledPayload`) via
/// the ObjC++ bridge — not a Swift reimplementation — so iOS, Android, and
/// the core agree byte-for-byte.
public struct ScheduledPayload: Sendable, Equatable {
    /// The user payload (the beep `code`, typically a 5-char base-32 key).
    public let code: String

    /// The rounded timestamp in seconds, recovered from the trailer.
    public let timestampSec: Int

    public init(code: String, timestampSec: Int) {
        self.code = code
        self.timestampSec = timestampSec
    }
}
