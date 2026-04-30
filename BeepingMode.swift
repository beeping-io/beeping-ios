//
//  BeepingMode.swift
//  Beeping
//
//  Internal Swift mirror of `EnumBeepingMode` (BeepingCore.h). Kept
//  internal during BEE-68 — the legacy ObjC `EnumBeepingMode` still drives
//  `BeepingCore.m` and `Beeping.m`. BEE-71 / BEE-72 promote the Swift
//  layer to public via `.local()` / `.cloud(apiKey:endpoint:)`.
//

import Foundation

/// Operating mode of the underlying decoder. Raw values match
/// `BEEPING_MODE_AUDIBLE..BEEPING_MODE_CUSTOM` from `BeepingCoreLib_api.h`,
/// **NOT** the legacy `MODE_AUDIBLE..MODE_CUSTOM` typedef in
/// `BeepingCore.h` (which conflated tokens and modes in one NS_ENUM).
///
/// Promoted from `internal` to `public` in BEE-70 because it appears in
/// `BeepingClient.init(mode:)`. Factory methods that wrap mode selection
/// (`.local()` / `.cloud(...)`) land in BEE-71/72.
public enum BeepingMode: Int32, Sendable {
    /// Old audible mode. Deprecated in `BeepingCoreLib_api.h`; kept only
    /// for completeness — do not select.
    case audibleOld    = 0

    /// Old non-audible mode. Deprecated; do not select.
    case nonAudibleOld = 1

    /// Audible tones in the human-hearing band.
    case audible       = 2

    /// Non-audible (ultrasonic) tones above ~16 kHz.
    case nonAudible    = 3

    /// Hidden tones — perceptually masked carrier.
    case hidden        = 4

    /// Decoder accepts any of the above; call `decodedMode` to find which
    /// one was matched.
    case all           = 5

    /// Custom frequency range; use `setCustomBaseFreq:beepsSeparation:`
    /// to configure.
    case custom        = 6
}
