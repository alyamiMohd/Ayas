import SwiftUI

/// The single most important pixel in the app: an empty ring that becomes a filled check.
///
/// Shared between the app and the widget so completing a habit looks identical wherever it
/// happens. The satisfaction is meant to come from the fill and the stroke of the check —
/// no confetti, no badges.
/// The three colours a mark is drawn from. Overridable so the mark still reads when it
/// sits on a filled ground rather than the page.
struct MarkPalette: Equatable {
    var ring: Color
    var fill: Color
    var check: Color

    static func standard(_ accent: AccentKey) -> MarkPalette {
        MarkPalette(ring: Palette.lineStrong, fill: accent.color, check: Palette.onAccent)
    }

    /// For a mark on the completed widget's green face.
    static let onDoneGround = MarkPalette(
        ring: Palette.onDoneFaint,
        fill: Palette.onDone,
        check: Palette.doneGround
    )
}

struct CompletionMark: View {
    var isComplete: Bool
    var accent: AccentKey
    var size: CGFloat = 30
    /// Set when the mark sits on a filled ground and needs its own colours.
    var palette: MarkPalette?

    private var colors: MarkPalette { palette ?? .standard(accent) }
    private var strokeWidth: CGFloat { max(1.2, size * 0.055) }

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(colors.ring, lineWidth: strokeWidth)
                .opacity(isComplete ? 0 : 1)

            Circle()
                .fill(colors.fill)
                .scaleEffect(isComplete ? 1 : 0.35)
                .opacity(isComplete ? 1 : 0)

            CheckPath()
                .trim(from: 0, to: isComplete ? 1 : 0)
                .stroke(
                    colors.check,
                    style: StrokeStyle(lineWidth: size * 0.1, lineCap: .round, lineJoin: .round)
                )
                .frame(width: size * 0.40, height: size * 0.30)
                .offset(y: size * 0.01)
        }
        .frame(width: size, height: size)
        .animation(isComplete ? Motion.complete : Motion.undo, value: isComplete)
    }
}

/// A tick drawn as two strokes, so it can be trimmed into view.
struct CheckPath: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.52))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.35, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        return path
    }
}

/// The ring with a plus inside, used for the "add a habit" row so it sits in the same
/// rhythm as the habits above it.
struct AddMark: View {
    var size: CGFloat = 30

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(
                    Palette.lineStrong,
                    style: StrokeStyle(lineWidth: max(1.2, size * 0.055), dash: [2.4, 3.2])
                )
            Image(systemName: "plus")
                .font(.system(size: size * 0.38, weight: .medium))
                .foregroundStyle(Palette.inkFaint)
        }
        .frame(width: size, height: size)
    }
}
