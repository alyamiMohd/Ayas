import Foundation

/// Everything needed to draw a habit for one particular day, derived in one place so the
/// app row, the detail screen and the widget can never disagree.
struct HabitSnapshot: Identifiable, Hashable, Sendable {
    var id: UUID
    var name: String
    var action: String
    var glyph: Glyph
    var accent: AccentKey
    var day: DayKey
    var isComplete: Bool
    var streak: Int
    var totalCompletions: Int
    /// Today's step of an ordered habit, already resolved to text.
    var item: SequenceItem?

    init(habit: Habit, day: DayKey, includeTranslation: Bool = true, calendar: Calendar = .current) {
        id = habit.id
        name = habit.name
        action = habit.action
        glyph = habit.glyph
        accent = habit.accent
        self.day = day
        isComplete = habit.isComplete(on: day)
        streak = habit.currentStreak(asOf: day, calendar: calendar)
        totalCompletions = habit.totalCompletions
        item = SequenceResolver.item(
            for: habit.sequence,
            step: habit.dueStep(on: day),
            includeTranslation: includeTranslation
        )
    }

    /// "6 days" — the continuity line. Reads as a fact, not a score.
    var streakLabel: String {
        switch streak {
        case 0: return "No streak yet"
        case 1: return "1 day"
        default: return "\(streak) days"
        }
    }
}
