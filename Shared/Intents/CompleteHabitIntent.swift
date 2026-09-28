import AppIntents
import Foundation

/// Marks today's action done. This is what the widget's button runs, in-place, without ever
/// opening the app — one tap from the Home Screen to done.
///
/// Deliberately one-way: a widget tap can only ever complete, never un-complete, so a
/// misplaced thumb on the Home Screen cannot cost someone a streak. Undo lives in the app,
/// where the gesture is intentional.
struct CompleteHabitIntent: AppIntent {
    static var title: LocalizedStringResource { "Complete Habit" }

    static var description: IntentDescription {
        IntentDescription("Marks today's tiny action as done.")
    }

    @Parameter(title: "Habit")
    var habit: HabitEntity

    init() {}

    init(habit: HabitEntity) {
        self.habit = habit
    }

    func perform() async throws -> some IntentResult {
        HabitStore.shared.complete(id: habit.id)
        return .result()
    }
}
