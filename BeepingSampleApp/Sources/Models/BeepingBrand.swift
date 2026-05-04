import SwiftUI

/// Brand colors mirrored from `beeping-www/src/app/globals.css` (single
/// source of truth in the web repo). Update both when the brand evolves.
enum BeepingBrand {
    /// `--brand-red: #ed1c24`
    static let red = Color(red: 0xED / 255.0, green: 0x1C / 255.0, blue: 0x24 / 255.0)
    /// `--brand: #063045`
    static let primary = Color(red: 0x06 / 255.0, green: 0x30 / 255.0, blue: 0x45 / 255.0)
    /// `--brand-light: #0a4d6e`
    static let primaryLight = Color(red: 0x0A / 255.0, green: 0x4D / 255.0, blue: 0x6E / 255.0)
    /// `--brand-dark: #042231`
    static let primaryDark = Color(red: 0x04 / 255.0, green: 0x22 / 255.0, blue: 0x31 / 255.0)
}
