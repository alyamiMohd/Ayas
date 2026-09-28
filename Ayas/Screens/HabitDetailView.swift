import SwiftUI

/// One habit, in full: today's content, the single control that completes it, and just
/// enough history to show continuity.
struct HabitDetailView: View {
    var habitID: UUID
    var onBack: () -> Void
    var onEdit: () -> Void

    @Environment(HabitStore.self) private var store

    private var habit: Habit? { store.habit(id: habitID) }
    private var today: DayKey { store.today() }

    var body: some View {
        ZStack {
            CanvasBackground()

            if let habit {
                content(for: habit)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private func content(for habit: Habit) -> some View {
        let snapshot = HabitSnapshot(
            habit: habit,
            day: today,
            includeTranslation: store.settings.showTranslation
        )

        return ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    CircleControl(symbol: "chevron.left", action: onBack)
                    Spacer()
                    CircleControl(symbol: "pencil", action: onEdit)
                }
                .padding(.top, Space.regular)
                .padding(.bottom, Space.roomy)

                VStack(alignment: .leading, spacing: Space.tight) {
                    Text(snapshot.action).eyebrow(color: snapshot.accent.color)
                    HStack(spacing: Space.snug) {
                        Image(systemName: snapshot.glyph.symbolName)
                            .font(.system(size: 18, weight: .regular))
                            .foregroundStyle(snapshot.accent.color)
                        Text(snapshot.name)
                            .font(TypeScale.screenTitle)
                            .foregroundStyle(Palette.ink)
                    }
                }

                if let item = snapshot.item {
                    AyahBlock(item: item, accent: snapshot.accent, isComplete: snapshot.isComplete)
                        .padding(.top, Space.roomy)
                }

                CompletionBar(
                    isComplete: snapshot.isComplete,
                    accent: snapshot.accent,
                    action: { toggle(snapshot) }
                )
                .padding(.top, Space.roomy)

                continuity(for: habit, snapshot: snapshot)
                    .padding(.top, Space.generous)

                Spacer(minLength: Space.generous)
            }
            .padding(.horizontal, Space.gutter)
        }
        .scrollIndicators(.hidden)
    }

    private func continuity(for habit: Habit, snapshot: HabitSnapshot) -> some View {
        VStack(alignment: .leading, spacing: Space.regular) {
            SectionLabel(text: "Continuity")

            HStack(alignment: .lastTextBaseline, spacing: Space.tight) {
                Text("\(snapshot.streak)")
                    .font(TypeScale.numeral(44))
                    .foregroundStyle(Palette.ink)
                    .contentTransition(.numericText())
                Text(snapshot.streak == 1 ? "day" : "days")
                    .font(TypeScale.body)
                    .foregroundStyle(Palette.inkSoft)
                    .padding(.bottom, 4)
            }

            Text(summary(for: habit, snapshot: snapshot))
                .font(TypeScale.caption)
                .foregroundStyle(Palette.inkFaint)

            WeekStrip(
                marks: habit.recentDays(endingOn: today, count: 14),
                accent: snapshot.accent,
                today: today
            )
            .padding(.top, Space.tight)
        }
        .animation(Motion.soft, value: snapshot.streak)
    }

    private func summary(for habit: Habit, snapshot: HabitSnapshot) -> String {
        var parts: [String] = []
        let best = habit.bestStreak()
        if best > snapshot.streak {
            parts.append("Best \(best) days")
        }
        parts.append(snapshot.totalCompletions == 1 ? "1 day in total" : "\(snapshot.totalCompletions) days in total")
        parts.append("Started \(DateText.shortDay(habit.createdOn))")
        return parts.joined(separator: " · ")
    }

    private func toggle(_ snapshot: HabitSnapshot) {
        withAnimation(snapshot.isComplete ? Motion.undo : Motion.complete) {
            let nowComplete = store.toggle(id: snapshot.id, on: today)
            if nowComplete {
                Haptics.completed(enabled: store.settings.haptics)
            } else {
                Haptics.undone(enabled: store.settings.haptics)
            }
        }
    }
}

/// The one big control on the screen. Wide enough to hit without looking.
private struct CompletionBar: View {
    var isComplete: Bool
    var accent: AccentKey
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Space.regular) {
                CompletionMark(isComplete: isComplete, accent: accent, size: 26)

                Text(isComplete ? "Completed today" : "Mark today done")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(isComplete ? accent.color : Palette.ink)

                Spacer(minLength: Space.snug)

                if isComplete {
                    Text("Undo").eyebrow(size: 10, color: Palette.inkFaint)
                }
            }
            .padding(.horizontal, Space.regular)
            .padding(.vertical, Space.regular)
            .background(
                RoundedRectangle(cornerRadius: Radius.medium, style: .continuous)
                    .fill(isComplete ? accent.wash : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Radius.medium, style: .continuous)
                    .strokeBorder(isComplete ? Color.clear : Palette.lineStrong, lineWidth: 0.9)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableStyle(scale: 0.985))
        .animation(Motion.soft, value: isComplete)
    }
}
