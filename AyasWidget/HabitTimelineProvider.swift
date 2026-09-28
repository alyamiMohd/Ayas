import AppIntents
import Foundation
import WidgetKit

struct HabitEntry: TimelineEntry {
    var date: Date
    var habit: HabitSnapshot?
    /// Distinguishes "you have no habits yet" from "the habit this widget pointed at is gone".
    var libraryHasHabits: Bool
}

/// Builds the widget's timeline.
///
/// The key detail: entries are pre-built for the next few day boundaries. WidgetKit renders
/// the right one as each boundary passes, so the day advances — new ayah, completion cleared,
/// streak recomputed — with no help from the app. Opening the app is never required for the
/// widget to be correct tomorrow morning.
struct HabitTimelineProvider: AppIntentTimelineProvider {
    /// How many days ahead to pre-render. Enough to stay correct through a weekend of the
    /// extension never being woken.
    private let lookaheadDays = 4

    func placeholder(in context: Context) -> HabitEntry {
        HabitEntry(date: Date(), habit: SampleData.snapshot(), libraryHasHabits: true)
    }

    func snapshot(for configuration: SelectHabitIntent, in context: Context) async -> HabitEntry {
        let document = DocumentStorage.shared.load()
        if let habit = resolveHabit(for: configuration, in: document) {
            return entry(at: Date(), habit: habit, settings: document.settings)
        }
        // The widget gallery should show something worth adding, not an empty prompt.
        if context.isPreview {
            return HabitEntry(date: Date(), habit: SampleData.snapshot(), libraryHasHabits: true)
        }
        return HabitEntry(date: Date(), habit: nil, libraryHasHabits: !document.habits.isEmpty)
    }

    func timeline(for configuration: SelectHabitIntent, in context: Context) async -> Timeline<HabitEntry> {
        let document = DocumentStorage.shared.load()
        let now = Date()

        guard let habit = resolveHabit(for: configuration, in: document) else {
            let entry = HabitEntry(date: now, habit: nil, libraryHasHabits: !document.habits.isEmpty)
            let retry = DayClock.nextBoundary(after: now, dayStartHour: document.settings.dayStartHour)
            return Timeline(entries: [entry], policy: .after(retry))
        }

        let settings = document.settings
        var entries = [entry(at: now, habit: habit, settings: settings)]
        var boundary = DayClock.nextBoundary(after: now, dayStartHour: settings.dayStartHour)

        for _ in 0..<lookaheadDays {
            entries.append(entry(at: boundary, habit: habit, settings: settings))
            boundary = DayClock.nextBoundary(after: boundary, dayStartHour: settings.dayStartHour)
        }

        return Timeline(entries: entries, policy: .atEnd)
    }

    private func entry(at date: Date, habit: Habit, settings: Settings) -> HabitEntry {
        let day = DayKey(date, dayStartHour: settings.dayStartHour)
        return HabitEntry(
            date: date,
            habit: HabitSnapshot(habit: habit, day: day, includeTranslation: settings.showTranslation),
            libraryHasHabits: true
        )
    }

    /// Falls back to the first habit so a freshly added widget shows something immediately,
    /// and so deleting a habit does not leave a dead widget behind.
    private func resolveHabit(for configuration: SelectHabitIntent, in document: AyasDocument) -> Habit? {
        if let chosen = configuration.habit?.id,
           let match = document.habits.first(where: { $0.id == chosen }) {
            return match
        }
        return document.habits.first
    }
}

/// Content for the widget gallery and the placeholder, so neither ever looks broken.
enum SampleData {
    static func snapshot() -> HabitSnapshot {
        let today = DayKey(Date())
        var habit = HabitTemplate.quran.makeHabit(createdOn: today.adding(days: -6))
        for offset in 1...6 {
            habit.markComplete(on: today.adding(days: -offset))
        }
        return HabitSnapshot(habit: habit, day: today, includeTranslation: false)
    }
}
