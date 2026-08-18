//
//  LocalEncoder.swift
//  Beeping
//
//  `BeepingEncoder` strategy that runs the encoder locally on-device.
//  Wraps `BeepingCoreWrapper.play(code:)`, which in turn drives the
//  `BCNativeCore` ObjC++ bridge (BEE-68 phase 2) to encode the payload
//  via the C engine and emit through the RemoteIO audio unit
//  (BEE-68 phase 4 `AudioEngine`).
//
//  Actor isolation guarantees the wrapper isn't called concurrently
//  from multiple `encode(_:)` calls on the same encoder instance —
//  important because the wrapper's internal state (`_isEmitting`,
//  encoded buffer index) isn't itself thread-safe across encode cycles.
//

import Foundation

internal actor LocalEncoder: BeepingEncoder {
    private let wrapper: BeepingCoreWrapper

    /// Constructed with an existing `BeepingCoreWrapper` so a single
    /// engine handle is shared between encode (this strategy) and decode
    /// (the listening path inside `BeepingClient`). When `BeepingClient`
    /// wants a Local-mode encoder, it passes its own wrapper here.
    internal init(wrapper: BeepingCoreWrapper) {
        self.wrapper = wrapper
    }

    func encode(_ payload: BeepingPayload) async throws {
        // BEE-2355: the caller supplies a 5-char **key** — the public
        // contract, per beepbox's OpenAPI (`^[0-9a-v]{5}$`). Composing the
        // 9-char wire string is the SDK's job, not the caller's. Before
        // this, `encode` demanded the composed form and rejected every
        // valid key with `decoderInternal`.
        let wire = try Self.wireString(for: payload)

        // The legacy C engine doesn't surface errors past validation, but
        // the audio session can still refuse to activate — BEE-2351 makes
        // that a thrown error rather than a process abort.
        try wrapper.play(code: wire)
    }

    // MARK: - Wire format

    /// Base-32 alphabet shared by the key and the timestamp tag: digits
    /// `0-9` then letters `a-v`. Exactly 32 symbols because the C engine's
    /// Reed-Solomon code lives in GF(2⁵) — `'v'` is symbol 31 and there is
    /// no room for `w`…`z`.
    private static let alphabet = Array("0123456789abcdefghijklmnopqrstuv")

    /// Number of base-32 chars the timestamp tag occupies.
    private static let timestampChars = 4

    /// Composes the 9-char string the C engine encodes: the 5-char key
    /// followed by the rounded timestamp in seconds as a 4-char
    /// zero-padded base-32 tag.
    ///
    /// Mirrors `BEEPING_EncodeWithSchedule`, whose contract states the
    /// payload is *"`code` concatenated with the rounded timestamp of the
    /// beep in seconds, encoded as 4-char zero-padded base-32"*, and is the
    /// exact inverse of `BEEPING_ParseScheduledPayload`.
    internal static func wireString(for payload: BeepingPayload) throws -> String {
        let key =
            payload.key.isEmpty
            ? String(payload.decodedString.prefix(5))
            : payload.key
        try validateKey(key)
        return key + base32Tag(payload.timestamp)
    }

    /// The public contract is `^[0-9a-v]{5}$` — 5 chars, lowercase.
    ///
    /// Note the SDK is deliberately stricter than the engine here: the C
    /// `getIdxFromChar` accepts `'V'` as well as `'v'`, but the published
    /// beepbox API only admits lowercase, and diverging would let a key
    /// encode locally that the server would reject.
    private static func validateKey(_ key: String) throws {
        guard key.count == 5 else {
            throw BeepingError.decoderInternal(
                reason: "LocalEncoder: key must be 5 base32 chars (got \(key.count) in \"\(key)\")")
        }
        let allowed = Set(alphabet)
        for c in key where !allowed.contains(c) {
            throw BeepingError.decoderInternal(
                reason: """
                    LocalEncoder: key "\(key)" contains '\(c)', which is outside \
                    the base32 alphabet [0-9a-v] (lowercase only)
                    """)
        }
    }

    /// Encodes `seconds` as a zero-padded 4-char base-32 tag.
    ///
    /// Values are taken modulo 32⁴ (1 048 576 s ≈ 12 days) because that is
    /// all four chars can carry; negatives are clamped to 0 rather than
    /// wrapping to a far-future tag.
    private static func base32Tag(_ seconds: Int) -> String {
        let modulus = Int(pow(32.0, Double(timestampChars)))
        var value = seconds <= 0 ? 0 : seconds % modulus
        var chars = [Character]()
        for _ in 0..<timestampChars {
            chars.append(alphabet[value % 32])
            value /= 32
        }
        return String(chars.reversed())
    }
}
