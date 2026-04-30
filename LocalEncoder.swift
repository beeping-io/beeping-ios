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
        // The legacy C engine doesn't surface errors; play(code:) is
        // fire-and-forget. If a future engine version returns a status
        // we can map it to BeepingError here.
        wrapper.play(code: payload.decodedString)
    }
}
