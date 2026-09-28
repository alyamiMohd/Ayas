import SwiftUI

/// The home screen of the app: what am I doing today, and is it done?
///
/// Nothing else earns a place here. No charts, no totals, no encouragement copy — just the
/// short list and the rings.
struct TodayView: View {
    @Environment(HabitStore.self) private var store

    var onOpen: (UUID) -> Void
    var onCreate: () -> Void
    var onQuickStart: () -> Void
    var onSettings: () -> Void

    private var today: DayKey { store.today() }

    private var snapshots: [HabitSnapshot] {
        store.habits.map { HabitSnapshot(habit: $0, day: today, includeTranslation: false) }
    }

    private var doneCount: Int {
        snapshots.filter(\.isComplete).count
    }

    private var subtitle: String? {
        guard !snapshots.isEmpty else { return nil }
        if doneCount == snapshots.count {
            return snapshots.count == 1 ? "Done for today." : "All done today."
        }
        return "\(doneCount) of \(snapshots.count) done today."
    }

    var body: some View {
        ZStack {
            CanvasBackground()

            if store.habits.isEmpty {
                EmptyStateView(onQuickStart: onQuickStart, onCustom: onCreate)
                    .padding(.horizontal, Space.gutter)
            } else {
                list
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var list: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ScreenHeader(
                    eyebrow: DateText.longDay(today),
                    title: "Today",
                    subtitle: subtitle
                ) {
                    CircleControl(symbol: "slider.horizontal.3", action: onSettings)
                }
                .padding(.top, Space.regular)
                .padding(.bottom, Space.roomy)

                ForEach(snapshots) { snapshot in
                    HabitRow(
                        snapshot: snapshot,
                        onToggle: { toggle(snapshot) },
                        onOpen: { onOpen(snapshot.id) }
                    )
                    Hairline(inset: 46)
                }

                AddHabitRow(action: onCreate)

                Spacer(minLength: Space.generous)
            }
            .padding(.horizontal, Space.gutter)
        }
        .scrollIndicators(.hidden)
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
