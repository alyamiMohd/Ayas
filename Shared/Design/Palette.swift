import SwiftUI
import UIKit

/// The app's colour identity: warm paper in the light, warm near-black in the dark.
///
/// Both modes are drawn deliberately rather than inverted — the light mode leans to paper
/// and sand, the dark mode to ink and ember, and neither uses a system blue anywhere.
/// Every colour is an adaptive `UIColor` underneath, so mode changes cross-fade naturally.
enum Palette {
    /// The page itself.
    static let canvas = Color(light: 0xF7F3ED, dark: 0x121110)
    /// A slightly recessed wash, used behind quiet areas.
    static let canvasLow = Color(light: 0xEFE8DD, dark: 0x0B0A09)
    /// Raised surfaces — sheets, the widget's own ground.
    static let surface = Color(light: 0xFFFCF8, dark: 0x1C1A18)

    static let ink = Color(light: 0x211E1A, dark: 0xF4EFE8)
    static let inkSoft = Color(light: 0x5D564D, dark: 0xA9A099)
    static let inkFaint = Color(light: 0x9A9188, dark: 0x6D645D)

    static let line = Color(light: 0xE4DBCE, dark: 0x2B2825)
    static let lineStrong = Color(light: 0xD2C7B7, dark: 0x3B3733)

    /// Sits on top of a filled accent — the checkmark, mostly.
    static let onAccent = Color(light: 0xFFFDFA, dark: 0x17140F)

    /// The completed widget's ground.
    ///
    /// One green for every habit, whatever its own accent: done is done, and the whole
    /// face turning is what makes it readable from across the room.
    static let doneGround = Color(light: 0x4C7A4F, dark: 0x2B5136)
    static let doneGroundEdge = Color(light: 0x3E6742, dark: 0x1D3826)

    static let onDone = Color(light: 0xF5F9F2, dark: 0xE2EFDE)
    static let onDoneSoft = Color(light: 0xDCE9D7, dark: 0xB6CFB1)
    static let onDoneFaint = Color(light: 0xC0D6BC, dark: 0x9BB899)
}

extension AccentKey {
    var color: Color {
        switch self {
        case .ember: return Color(light: 0xBE6136, dark: 0xE08C5F)
        case .olive: return Color(light: 0x5F7A50, dark: 0x9BB884)
        case .indigo: return Color(light: 0x4B5A7C, dark: 0x8C9DC4)
        case .rose: return Color(light: 0xA4505F, dark: 0xD4818E)
        case .sand: return Color(light: 0x8F7040, dark: 0xC8A469)
        case .teal: return Color(light: 0x3B7269, dark: 0x7DB3A8)
        }
    }

    /// A soft tint of the accent, for fills that must not shout.
    var wash: Color {
        switch self {
        case .ember: return Color(light: 0xF3E5DB, dark: 0x2A1F19)
        case .olive: return Color(light: 0xE7EBE0, dark: 0x1B211A)
        case .indigo: return Color(light: 0xE3E6EF, dark: 0x1A1D26)
        case .rose: return Color(light: 0xF2E2E4, dark: 0x261A1D)
        case .sand: return Color(light: 0xF1E8D7, dark: 0x241F16)
        case .teal: return Color(light: 0xDFEAE7, dark: 0x16211F)
        }
    }

    var label: String {
        switch self {
        case .ember: return "Ember"
        case .olive: return "Olive"
        case .indigo: return "Dusk"
        case .rose: return "Rose"
        case .sand: return "Sand"
        case .teal: return "Teal"
        }
    }
}

extension AppearanceChoice {
    /// Nil follows the system, which is the default and the one most people keep.
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

extension Color {
    /// Adaptive colour from two hex literals, so light and dark can be tuned independently.
    init(light: UInt32, dark: UInt32) {
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(rgb: dark) : UIColor(rgb: light)
        })
    }
}

extension UIColor {
    convenience init(rgb: UInt32) {
        self.init(
            red: CGFloat((rgb >> 16) & 0xFF) / 255,
            green: CGFloat((rgb >> 8) & 0xFF) / 255,
            blue: CGFloat(rgb & 0xFF) / 255,
            alpha: 1
        )
    }
}
