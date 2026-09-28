import AppIntents
import Foundation

/// A habit as the system sees it — what the widget configuration picker offers, and what
/// the completion intent takes as its subject.
struct HabitEntity: AppEntity, Identifiable, Hashable, Sendable {
    var id: UUID
    var name: String
    var action: String

    init(id: UUID, name: String, action: String) {
        self.id = id
        self.name = name
        self.action = action
    }

    init(habit: Habit) {
        self.init(id: habit.id, name: habit.name, action: habit.action)
    }

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Habit")
    }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)", subtitle: "\(action)")
    }

    static var defaultQuery: HabitQuery { HabitQuery() }
}

/// Reads habits straight from the shared document rather than through the observable store,
/// so the configuration picker always reflects what is on disk right now.
struct HabitQuery: EntityQuery {
    func entities(for identifiers: [UUID]) async throws -> [HabitEntity] {
        let wanted = Set(identifiers)
        return DocumentStorage.shared.load().habits
            .filter { wanted.contains($0.id) }
            .map(HabitEntity.init(habit:))
    }

    func suggestedEntities() async throws -> [HabitEntity] {
        DocumentStorage.shared.load().habits.map(HabitEntity.init(habit:))
    }
}
