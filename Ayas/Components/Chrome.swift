import SwiftUI

/// Shared furniture: headers, hairlines and button styles, so every screen is built from the
/// same small set of parts instead of one-off layouts.

/// A screen's own header. The app hides the system navigation bar and draws this instead —
/// that is most of what keeps it from looking like a stock template.
struct ScreenHeader<Trailing: View>: View {
    var eyebrow: String?
    var title: String
    var subtitle: String?
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        VStack(alignment: .leading, spacing: Space.tight) {
            HStack(alignment: .firstTextBaseline) {
                if let eyebrow {
                    Text(eyebrow).eyebrow()
                }
                Spacer(minLength: Space.snug)
                trailing()
            }

            Text(title)
                .font(TypeScale.screenTitle)
                .foregroundStyle(Palette.ink)

            if let subtitle {
                Text(subtitle)
                    .font(TypeScale.body)
                    .foregroundStyle(Palette.inkSoft)
                    .padding(.top, 2)
            }
        }
    }
}

struct Hairline: View {
    var inset: CGFloat = 0

    var body: some View {
        Rectangle()
            .fill(Palette.line)
            .frame(height: 0.75)
            .padding(.leading, inset)
    }
}

/// A small circular control — settings, back, dismiss. Reads as a mark, not a chrome button.
struct CircleControl: View {
    var symbol: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Palette.inkSoft)
                .frame(width: 34, height: 34)
                .background(Circle().fill(Palette.canvasLow))
                .overlay(Circle().strokeBorder(Palette.line, lineWidth: 0.75))
        }
        .buttonStyle(PressableStyle())
    }
}

/// Press feedback used everywhere, so nothing in the app feels inert.
struct PressableStyle: ButtonStyle {
    var scale: CGFloat = 0.96

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .opacity(configuration.isPressed ? 0.75 : 1)
            .animation(Motion.soft, value: configuration.isPressed)
    }
}

/// Filled pill. Used once per screen at most.
struct FilledButtonStyle: ButtonStyle {
    var fill: Color = Palette.ink
    var foreground: Color = Palette.canvas

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(foreground)
            .padding(.vertical, 15)
            .frame(maxWidth: .infinity)
            .background(Capsule().fill(fill))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(Motion.soft, value: configuration.isPressed)
    }
}

/// Hairline pill, for the secondary path.
struct OutlineButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .regular))
            .foregroundStyle(Palette.inkSoft)
            .padding(.vertical, 15)
            .frame(maxWidth: .infinity)
            .background(Capsule().strokeBorder(Palette.lineStrong, lineWidth: 0.9))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(Motion.soft, value: configuration.isPressed)
    }
}

/// A labelled text field with a hairline underneath — no boxed form rows anywhere in the app.
struct UnderlinedField: View {
    var label: String
    var placeholder: String
    @Binding var text: String
    var accent: AccentKey = .ember

    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Space.tight) {
            Text(label).eyebrow()

            TextField(placeholder, text: $text)
                .font(TypeScale.sectionTitle)
                .foregroundStyle(Palette.ink)
                .tint(accent.color)
                .focused($focused)
                .submitLabel(.done)

            Rectangle()
                .fill(focused ? accent.color : Palette.line)
                .frame(height: focused ? 1.4 : 0.75)
                .animation(Motion.soft, value: focused)
        }
    }
}

/// Section label used inside detail and settings screens.
struct SectionLabel: View {
    var text: String

    var body: some View {
        Text(text)
            .eyebrow()
            .padding(.bottom, Space.tight)
    }
}

/// The page background: warm, with a barely-there fall-off so it is not a flat slab.
struct CanvasBackground: View {
    var body: some View {
        LinearGradient(
            colors: [Palette.canvas, Palette.canvasLow],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}
