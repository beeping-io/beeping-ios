//
//  BeepboxAPITypes.swift
//  Beeping
//
//  Codable types mirroring the `beepbox-server` OpenAPI 3.1 spec at
//  `/OpenAPI/openapi.yaml` (vendored from
//  `beeping-io/beepbox/docs/openapi.yaml`).
//
//  ## Why hand-written?
//
//  Apple's `swift-openapi-generator` is a Swift Package Manager build
//  plugin. It requires `Package.swift` to integrate, which the
//  beeping-ios framework gets in BEE-80. Until then, these types are
//  **manually mirrored** to match the spec — every property here has a
//  one-to-one correspondence with a schema in `openapi.yaml`. When BEE-80
//  lands the SPM build plugin, this file is deleted and replaced by the
//  generator's `Types.swift`.
//
//  ## Sync policy
//
//  The openapi.yaml is a vendored snapshot. When `beepbox-server`
//  changes its spec, re-run:
//
//      cp ../beepbox/docs/openapi.yaml OpenAPI/openapi.yaml
//
//  …and update these types to match. CI gates the YAML for syntax but
//  cannot detect drift between the spec and these hand-written types
//  (BEE-80 fixes this by generating).
//

import Foundation

// MARK: - EncodeRequest (POST /v1/encode body)

/// Request body for `POST /v1/encode`. Mirrors `EncodeRequest` schema.
internal struct EncodeRequest: Codable, Sendable, Equatable {

    /// 5-character base32 payload to encode. Pattern: `^[0-9a-v]{5}$`.
    let key: String

    /// Encoding mode. Default `.inaudible`. Server enum:
    /// `audible | inaudible | all`.
    let mode: Mode?

    /// Audio sample rate in Hz. 22050..96000, default 44100.0.
    let sampleRate: Double?

    /// Total audio duration in seconds. Min 2.3, default 2.3.
    let duration: Double?

    /// Offset in seconds before the first beep. Default 0.0.
    let start: Double?

    /// Seconds between beep repetitions. Min 2.3, default 2.3.
    let interval: Double?

    /// Beep gain in dB. -60..12, default -3.0.
    let volumeBeeps: Double?

    internal init(
        key: String,
        mode: Mode? = nil,
        sampleRate: Double? = nil,
        duration: Double? = nil,
        start: Double? = nil,
        interval: Double? = nil,
        volumeBeeps: Double? = nil
    ) {
        self.key = key
        self.mode = mode
        self.sampleRate = sampleRate
        self.duration = duration
        self.start = start
        self.interval = interval
        self.volumeBeeps = volumeBeeps
    }

    /// Encoding mode enum (audible / inaudible / all). Distinct from the
    /// SDK-level `BeepingMode` (which mirrors the local C engine's enum
    /// shape); a future helper could map between them.
    internal enum Mode: String, Codable, Sendable {
        case audible
        case inaudible
        case all
    }
}

// MARK: - ErrorResponse (4xx / 5xx generic body)

/// Mirrors `ErrorResponse` schema. Used by 429 and 500 responses.
internal struct ErrorResponse: Codable, Sendable, Equatable {
    let error: String
    let hint: String?
}

// MARK: - ValidationErrorResponse (400 body)

/// Mirrors `ValidationErrorResponse` schema. The 400 response can carry
/// either a single `error` string OR an array of `errors`; both fields
/// are optional in the spec, server picks one based on context.
internal struct ValidationErrorResponse: Codable, Sendable, Equatable {
    let error: String?
    let errors: [String]?

    /// Convenience: returns whichever shape the server used as a
    /// human-readable string for surfacing through `BeepingError`.
    var displayMessage: String {
        if let errors, !errors.isEmpty {
            return errors.joined(separator: "; ")
        }
        return error ?? "Validation failed"
    }
}
