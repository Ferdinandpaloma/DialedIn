import SwiftUI

extension Color {
    /// Creates an sRGB color from a 0xRRGGBB literal.
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}

/// ONDO design tokens, matched to the pitch deck.
enum Theme {
    static let navy = Color(hex: 0x0F2A3D)
    static let orange = Color(hex: 0xEB6834)
    static let blue = Color(hex: 0x2A78D6)
    static let green = Color(hex: 0x1BAF7A)
    static let red = Color(hex: 0xE34948)
    static let card = Color(hex: 0xF3F6F8)
    static let ink = Color(hex: 0x1B1B1B)

    /// Supporting tones (not in the deck palette, used sparingly).
    static let yellow = Color(hex: 0xF2C230)
    static let secondaryInk = Color(hex: 0x4A5560)   // ≥ 7:1 on white and on `card`
    static let hairline = Color(hex: 0xD9E0E6)
    static let offGray = Color(hex: 0xA9B4BE)        // "OFF" label on the dark dial face
    static let redDeep = Color(hex: 0xB3302E)        // red text on light tints (≥ 5:1)

    /// Calm surfaces: soft gray page, white cards with a faint shadow.
    static let background = card
    static let surface = Color.white
    static let shadow = navy.opacity(0.07)

    static let cornerRadius: CGFloat = 20
    static let spacing: CGFloat = 20
}
