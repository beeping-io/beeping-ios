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
        // Defensive validation: the C engine's ReedSolomon path SIGSEGVs
        // when fed non-base32 input (any char outside `[0-9a-v]`, or a
        // length other than the expected 9 chars: 5 key + 4 timestamp).
        // Throw a typed error so callers see a clean failure instead of
        // a process crash. Upstream beeping-core should also reject the
        // same input but the SDK can't depend on that yet.
        try Self.validateForCEngine(code: payload.decodedString)

        // The legacy C engine doesn't surface errors past validation, but
        // the audio session can still refuse to activate — BEE-2351 makes
        // that a thrown error rather than a process abort.
        try wrapper.play(code: payload.decodedString)
    }

    /// Beepbox payloads are 9 lowercase base32 chars: 5-char key +
    /// 4-char timestamp. Anything else is rejected at the Swift layer
    /// to prevent the C engine from crashing on malformed input.
    private static func validateForCEngine(code: String) throws {
        guard code.count == 9 else {
            throw BeepingError.decoderInternal(
                reason: "LocalEncoder: payload must be 9 base32 chars (got \(code.count))")
        }
        let allowed = Set("0123456789abcdefghijklmnopqrstuv")
        for c in code where !allowed.contains(c) {
            throw BeepingError.decoderInternal(
                reason: "LocalEncoder: payload \"\(code)\" contains non-base32 char '\(c)'")
        }
    }
}
