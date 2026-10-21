import Foundation
import Observation
import WidgetKit

/// Widget kind identifiers, shared so the app can refresh timelines by name.
enum WidgetKinds {
    static let habit = "AyasHabitWidget"
}

/// The one place habit state is mutated.
///
/// Every mutation writes the document straight through to disk and asks WidgetKit to
/// rebuild its timelines. Nothing is cached in memory across launches, so termination,
/// a device restart, or a write from the widget all land in the same state.
@Observable
final class HabitStore {
    static let shared = HabitStore()

    private let storage: DocumentStorage
    private(set) var document: AyasDocument

    init(storage: DocumentStorage = .shared) {
        self.storage = storage
        document = storage.load()
    }

    // MARK: - Reading

    var habits: [Habit] { document.habits }
    var settings: Settings { document.settings }
    var isSharedWithWidget: Bool { storage.isShared }

    func habit(id: UUID) -> Habit? {
        document.habits.first { $0.id == id }
    }

    func today(now: Date = Date()) -> DayKey {
        DayClock.today(dayStartHour: document.settings.dayStartHour, now: now)
    }

    /// Picks up writes made by the widget while the app was away. Called on every
    /// foreground and before every mutation.
    ///
    /// Reads the file every time rather than comparing modification dates: two writes can
    /// land inside the same timestamp granularity, and a missed refresh means the app
    /// silently clobbers whatever the widget just recorded. The document is a few kilobytes,
    /// so the read costs nothing. Assigning only on a real change keeps observation quiet.
    func refreshFromDisk() {
        let loaded = storage.load()
        guard loaded != document else { return }
        document = loaded
    }

    // MARK: - Habits

    func add(_ habit: Habit) {
        refreshFromDisk()
        document.habits.append(habit)
        commit()
    }

    func update(_ habit: Habit) {
        refreshFromDisk()
        guard let index = document.habits.firstIndex(where: { $0.id == habit.id }) else { return }
        document.habits[index] = habit
        commit()
    }

    func delete(id: UUID) {
        refreshFromDisk()
        document.habits.removeAll { $0.id == id }
        commit()
    }

    // MARK: - Completion

    /// Returns true when this call actually changed something, so callers can decide
    /// whether to celebrate. A second tap on an already-complete day returns false.
    @discardableResult
    func complete(id: UUID, on day: DayKey? = nil) -> Bool {
        refreshFromDisk()
        guard let index = document.habits.firstIndex(where: { $0.id == id }) else { return false }
        let target = day ?? today()
        let changed = document.habits[index].markComplete(on: target)
        if changed { commit() }
        return changed
    }

    @discardableResult
    func clear(id: UUID, on day: DayKey? = nil) -> Bool {
        refreshFromDisk()
        guard let index = document.habits.firstIndex(where: { $0.id == id }) else { return false }
        let target = day ?? today()
        let changed = document.habits[index].clearCompletion(on: target)
        if changed { commit() }
        return changed
    }

    /// Returns the state the habit ended up in.
    @discardableResult
    func toggle(id: UUID, on day: DayKey? = nil) -> Bool {
        refreshFromDisk()
        guard let habit = habit(id: id) else { return false }
        let target = day ?? today()
        if habit.isComplete(on: target) {
            clear(id: id, on: target)
            return false
        } else {
            complete(id: id, on: target)
            return true
        }
    }

    // MARK: - Settings

    func updateSettings(_ transform: (inout Settings) -> Void) {
        refreshFromDisk()
        transform(&document.settings)
        commit()
    }

    func eraseEverything() {
        document = AyasDocument()
        storage.save(document)
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Commit

    private func commit() {
        storage.save(document)
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetKinds.habit)
    }
}
