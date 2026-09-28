import SwiftUI

/// One habit on the Today screen.
///
/// Rows, not cards: hairlines separate them and the page shows through, which keeps the
/// screen reading as a short list of intentions rather than a dashboard.
struct HabitRow: View {
    var snapshot: HabitSnapshot
    var onToggle: () -> Void
    var onOpen: () -> Void

    private var metaColor: Color {
        snapshot.isComplete ? snapshot.accent.color : Palette.inkFaint
    }

    var body: some View {
        HStack(alignment: .top, spacing: Space.regular) {
            Button(action: onToggle) {
                CompletionMark(isComplete: snapshot.isComplete, accent: snapshot.accent, size: 30)
                    // A generous target around a small mark.
                    .padding(Space.tight)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PressableStyle(scale: 0.88))
            .accessibilityLabel(snapshot.isComplete ? "Mark \(snapshot.name) not done" : "Mark \(snapshot.name) done")
            .accessibilityAddTraits(snapshot.isComplete ? [.isButton, .isSelected] : .isButton)

            Button(action: onOpen) {
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: Space.tight) {
                        Image(systemName: snapshot.glyph.symbolName)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(snapshot.accent.color)
                        Text(snapshot.name)
                            .font(TypeScale.habitName)
                            .foregroundStyle(Palette.ink)
                    }

                    HStack(spacing: 6) {
                        Text(snapshot.action)
                            .font(TypeScale.bodySmall)
                            .foregroundStyle(Palette.inkSoft)
                        Text("·")
                            .font(TypeScale.bodySmall)
                            .foregroundStyle(Palette.inkFaint)
                        Text(snapshot.streakLabel)
                            .font(.system(size: 13, weight: snapshot.isComplete ? .medium : .regular))
                            .foregroundStyle(metaColor)
                            .contentTransition(.numericText())
                    }

                    if let reference = snapshot.item?.reference {
                        Text(reference)
                            .eyebrow(size: 10, color: snapshot.isComplete ? snapshot.accent.color : Palette.inkFaint)
                            .padding(.top, 1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, Space.tight)
                .contentShape(Rectangle())
            }
            .buttonStyle(PressableStyle(scale: 0.995))
            .accessibilityHint("Opens \(snapshot.name)")
        }
        .padding(.vertical, Space.snug)
        .animation(Motion.soft, value: snapshot.isComplete)
        .animation(Motion.soft, value: snapshot.streak)
    }
}

/// Sits at the end of the list in the same rhythm as the habits, so adding one feels like
/// part of the page rather than a floating control.
struct AddHabitRow: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Space.regular) {
                AddMark(size: 30)
                    .padding(Space.tight)
                Text("Add a habit")
                    .font(TypeScale.habitNameCompact)
                    .foregroundStyle(Palette.inkFaint)
                Spacer(minLength: 0)
            }
            .padding(.vertical, Space.snug)
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableStyle(scale: 0.99))
    }
}
