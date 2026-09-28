import SwiftUI

/// A two-voice type system: a serif for anything that carries meaning, a quiet sans for
/// labels and mechanics. The serif is what stops the app reading as a system template.
enum TypeScale {
    static let screenTitle = Font.system(size: 34, weight: .regular, design: .serif)
    static let sectionTitle = Font.system(size: 22, weight: .regular, design: .serif)
    static let habitName = Font.system(size: 21, weight: .regular, design: .serif)
    static let habitNameCompact = Font.system(size: 17, weight: .regular, design: .serif)

    static let body = Font.system(size: 15, weight: .regular)
    static let bodySmall = Font.system(size: 13, weight: .regular)
    static let caption = Font.system(size: 12, weight: .regular)

    /// Large numerals read better with the serif's older figures.
    static func numeral(_ size: CGFloat) -> Font {
        .system(size: size, weight: .regular, design: .serif)
    }

    /// Arabic scripture. Sized generously — this is the thing the reader came for.
    static func arabic(_ size: CGFloat) -> Font {
        .system(size: size, weight: .regular)
    }
}

/// Small, letter-spaced, uppercase label. Used sparingly, as a locator rather than a shout.
struct EyebrowStyle: ViewModifier {
    var size: CGFloat = 11
    var color: Color = Palette.inkFaint

    func body(content: Content) -> some View {
        content
            .font(.system(size: size, weight: .semibold))
            .tracking(1.3)
            .textCase(.uppercase)
            .foregroundStyle(color)
    }
}

extension View {
    func eyebrow(size: CGFloat = 11, color: Color = Palette.inkFaint) -> some View {
        modifier(EyebrowStyle(size: size, color: color))
    }
}

/// Arabic text block: right-to-left, roomy line height, never cramped.
struct ArabicText: View {
    var text: String
    var size: CGFloat
    var lineLimit: Int?
    var color: Color = Palette.ink

    var body: some View {
        Text(text)
            .font(TypeScale.arabic(size))
            .foregroundStyle(color)
            .lineSpacing(size * 0.52)
            .multilineTextAlignment(.trailing)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .environment(\.layoutDirection, .rightToLeft)
            .lineLimit(lineLimit)
            .minimumScaleFactor(0.85)
    }
}
