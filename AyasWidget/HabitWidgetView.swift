import AppIntents
import SwiftUI
import WidgetKit

/// The widget face. It has to answer four things at a glance: which habit, what today's step
/// is, how long the run is, and whether it is done.
struct HabitWidgetView: View {
    var entry: HabitEntry

    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            if let snapshot = entry.habit {
                habitFace(snapshot)
            } else {
                emptyFace
            }
        }
        .containerBackground(for: .widget) { background }
    }

    // MARK: - Habit

    private func habitFace(_ snapshot: HabitSnapshot) -> some View {
        let metrics = Metrics(family: family)

        return VStack(alignment: .leading, spacing: 0) {
            header(snapshot, metrics: metrics)

            Spacer(minLength: Space.tight)

            centrepiece(snapshot, metrics: metrics)

            Spacer(minLength: Space.tight)

            footer(snapshot, metrics: metrics)
        }
        .padding(metrics.padding)
        .widgetURL(DeepLink.habitURL(snapshot.id))
    }

    private func header(_ snapshot: HabitSnapshot, metrics: Metrics) -> some View {
        HStack(alignment: .center, spacing: 5) {
            Image(systemName: snapshot.glyph.symbolName)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(snapshot.accent.color)

            Text(snapshot.name)
                .eyebrow(size: 10, color: Palette.inkSoft)
                .lineLimit(1)

            Spacer(minLength: 4)

            if metrics.streakInHeader {
                streak(snapshot)
            }
        }
    }

    @ViewBuilder
    private func centrepiece(_ snapshot: HabitSnapshot, metrics: Metrics) -> some View {
        if let body = snapshot.item?.body {
            VStack(alignment: .leading, spacing: 6) {
                ArabicText(
                    text: body,
                    size: metrics.arabicSize,
                    lineLimit: metrics.arabicLines,
                    color: snapshot.isComplete ? Palette.inkSoft : Palette.ink
                )

                if metrics.allowsTranslation, let translation = snapshot.item?.translation {
                    Text(translation)
                        .font(.system(size: 11, weight: .regular, design: .serif))
                        .italic()
                        .foregroundStyle(Palette.inkFaint)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                        .multilineTextAlignment(.leading)
                }
            }
        } else {
            // Habits without ordered content lead with the action itself.
            Text(snapshot.action)
                .font(.system(size: metrics.actionSize, weight: .regular, design: .serif))
                .foregroundStyle(snapshot.isComplete ? Palette.inkSoft : Palette.ink)
                .lineLimit(3)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func footer(_ snapshot: HabitSnapshot, metrics: Metrics) -> some View {
        HStack(alignment: .center, spacing: Space.tight) {
            VStack(alignment: .leading, spacing: 2) {
                if snapshot.isComplete {
                    Text("Completed today")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(snapshot.accent.color)
                        .lineLimit(1)
                } else if let reference = snapshot.item?.reference {
                    Text(reference)
                        .eyebrow(size: 9, color: Palette.inkFaint)
                        .lineLimit(1)
                } else {
                    Text("Not done yet")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(Palette.inkFaint)
                        .lineLimit(1)
                }

                if !metrics.streakInHeader {
                    streak(snapshot)
                }
            }

            Spacer(minLength: 4)

            control(snapshot, metrics: metrics)
        }
    }

    private func streak(_ snapshot: HabitSnapshot) -> some View {
        Text(snapshot.streakLabel)
            .font(.system(size: 10, weight: snapshot.isComplete ? .medium : .regular))
            .foregroundStyle(snapshot.isComplete ? snapshot.accent.color : Palette.inkFaint)
            .lineLimit(1)
    }

    /// One tap from the Home Screen to done. Once complete the control becomes inert, so a
    /// second tap cannot undo a streak by accident — that lives in the app.
    @ViewBuilder
    private func control(_ snapshot: HabitSnapshot, metrics: Metrics) -> some View {
        if snapshot.isComplete {
            CompletionMark(isComplete: true, accent: snapshot.accent, size: metrics.markSize)
        } else {
            Button(
                intent: CompleteHabitIntent(
                    habit: HabitEntity(id: snapshot.id, name: snapshot.name, action: snapshot.action)
                )
            ) {
                CompletionMark(isComplete: false, accent: snapshot.accent, size: metrics.markSize)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Mark \(snapshot.name) done")
        }
    }

    // MARK: - Empty

    private var emptyFace: some View {
        VStack(alignment: .leading, spacing: Space.tight) {
            Spacer(minLength: 0)

            Circle()
                .strokeBorder(Palette.lineStrong, lineWidth: 1)
                .frame(width: 22, height: 22)
                .overlay(Circle().fill(AccentKey.olive.color).frame(width: 5, height: 5))

            Text(entry.libraryHasHabits ? "Pick a habit" : "One tiny thing a day")
                .font(.system(size: 15, weight: .regular, design: .serif))
                .foregroundStyle(Palette.ink)
                .lineLimit(2)

            Text(entry.libraryHasHabits
                 ? "Press and hold to choose which habit this shows."
                 : "Open Ayas to start something small.")
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(Palette.inkFaint)
                .lineLimit(3)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Metrics(family: family).padding)
        .widgetURL(DeepLink.rootURL)
    }

    // MARK: - Background

    @ViewBuilder
    private var background: some View {
        if let snapshot = entry.habit, snapshot.isComplete {
            // Completion warms the whole face — the reward is the widget itself changing.
            LinearGradient(
                colors: [snapshot.accent.wash, Palette.surface],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            LinearGradient(
                colors: [Palette.surface, Palette.canvas],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

/// Per-family sizing, kept in one place so adding a family later is a single case.
private struct Metrics {
    var padding: CGFloat
    var arabicSize: CGFloat
    var arabicLines: Int
    var actionSize: CGFloat
    var markSize: CGFloat
    var streakInHeader: Bool
    var allowsTranslation: Bool

    init(family: WidgetFamily) {
        switch family {
        case .systemSmall:
            padding = 15
            arabicSize = 14
            arabicLines = 3
            actionSize = 17
            markSize = 26
            streakInHeader = false
            allowsTranslation = false
        default:
            padding = 18
            arabicSize = 18
            arabicLines = 2
            actionSize = 22
            markSize = 30
            streakInHeader = true
            allowsTranslation = true
        }
    }
}
