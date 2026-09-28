import XCTest
@testable import Ayas

/// State has to survive termination, restarts and writes from the widget process, so the
/// document round trip and the store's disk-backed mutations are tested against a real file.
final class PersistenceTests: XCTestCase {
    private var directory: URL!
    private var storage: DocumentStorage!

    override func setUpWithError() throws {
        directory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("ayas-tests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        storage = DocumentStorage(fileURL: directory.appendingPathComponent("habits.json"))
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    func testMissingFileLoadsAnEmptyDocument() {
        let document = storage.load()
        XCTAssertTrue(document.habits.isEmpty)
        XCTAssertEqual(document.settings.dayStartHour, 0)
        XCTAssertEqual(document.settings.appearance, .system)
        XCTAssertFalse(storage.exists)
    }

    func testDocumentRoundTrip() {
        let today = DayKey(year: 2026, month: 9, day: 28)
        var habit = HabitTemplate.quran.makeHabit(createdOn: today)
        habit.markComplete(on: today.previous)
        habit.markComplete(on: today)

        var document = AyasDocument()
        document.habits = [habit, HabitTemplate.strength.makeHabit(createdOn: today)]
        document.settings.dayStartHour = 3
        document.settings.appearance = .dark
        document.settings.showTranslation = false

        storage.save(document)
        let reloaded = storage.load()

        XCTAssertEqual(reloaded.habits.count, 2)
        XCTAssertEqual(reloaded.habits.first?.id, habit.id)
        XCTAssertEqual(reloaded.habits.first?.name, "Quran")
        XCTAssertEqual(reloaded.habits.first?.completions.count, 2)
        XCTAssertEqual(reloaded.habits.first?.sequence, .quran(start: 1))
        XCTAssertEqual(reloaded.habits.last?.sequence, HabitSequence.none)
        XCTAssertEqual(reloaded.settings.dayStartHour, 3)
        XCTAssertEqual(reloaded.settings.appearance, .dark)
        XCTAssertFalse(reloaded.settings.showTranslation)
        XCTAssertEqual(reloaded, document)
    }

    func testDocumentFromAnOlderBuildStillOpens() throws {
        // Only the fields an early version would have written.
        let legacy = """
        {"habits":[{"id":"\(UUID().uuidString)","name":"Quran","action":"Read one ayah",\
        "glyph":"book","accent":"olive","sequence":{"kind":"quran","start":1},\
        "createdOn":20260901,"completions":[{"day":20260901,"step":0}]}]}
        """
        try Data(legacy.utf8).write(to: storage.fileURL)

        let document = storage.load()
        XCTAssertEqual(document.habits.count, 1)
        XCTAssertEqual(document.habits.first?.totalCompletions, 1)
        XCTAssertEqual(document.settings.dayStartHour, 0, "missing settings fall back to defaults")
        XCTAssertTrue(document.settings.haptics)
    }

    func testUnknownEnumValuesDegradeInsteadOfFailing() throws {
        let future = """
        {"habits":[{"id":"\(UUID().uuidString)","name":"Something","action":"Do it",\
        "glyph":"hologram","accent":"chartreuse","sequence":{"kind":"spiral","start":4},\
        "createdOn":20260901,"completions":[]}],"settings":{"appearance":"holographic"}}
        """
        try Data(future.utf8).write(to: storage.fileURL)

        let document = storage.load()
        XCTAssertEqual(document.habits.count, 1, "one unknown value must not lose the habit")
        XCTAssertEqual(document.habits.first?.glyph, .leaf)
        XCTAssertEqual(document.habits.first?.accent, .ember)
        XCTAssertEqual(document.habits.first?.sequence, HabitSequence.none)
        XCTAssertEqual(document.settings.appearance, .system)
    }

    func testUnreadableFileIsKeptAsideRatherThanLost() throws {
        try Data("this is not json".utf8).write(to: storage.fileURL)

        let document = storage.load()
        XCTAssertTrue(document.habits.isEmpty)

        let kept = try FileManager.default
            .contentsOfDirectory(atPath: directory.path)
            .filter { $0.hasPrefix("habits-unreadable-") }
        XCTAssertEqual(kept.count, 1, "the original bytes must still be on disk")
    }

    // MARK: - Store

    func testStorePersistsCompletionAcrossAFreshLoad() {
        let store = HabitStore(storage: storage)
        let today = store.today()
        store.add(HabitTemplate.quran.makeHabit(createdOn: today))

        guard let id = store.habits.first?.id else { return XCTFail("habit was not added") }
        XCTAssertTrue(store.complete(id: id, on: today))

        // A second process — or the app after being terminated — sees the same state.
        let reopened = HabitStore(storage: storage)
        XCTAssertEqual(reopened.habits.count, 1)
        XCTAssertTrue(reopened.habits.first?.isComplete(on: today) ?? false)
    }

    func testStoreIgnoresARepeatedCompletion() {
        let store = HabitStore(storage: storage)
        let today = store.today()
        store.add(HabitTemplate.strength.makeHabit(createdOn: today))
        guard let id = store.habits.first?.id else { return XCTFail("habit was not added") }

        XCTAssertTrue(store.complete(id: id, on: today))
        XCTAssertFalse(store.complete(id: id, on: today), "the widget tapping twice must not double count")
        XCTAssertEqual(store.habits.first?.totalCompletions, 1)
    }

    func testStorePicksUpAWriteFromAnotherProcess() {
        let store = HabitStore(storage: storage)
        let today = store.today()
        store.add(HabitTemplate.quran.makeHabit(createdOn: today))
        guard let id = store.habits.first?.id else { return XCTFail("habit was not added") }

        // Stand in for the widget extension completing the habit while the app is backgrounded.
        let widgetSide = HabitStore(storage: storage)
        XCTAssertTrue(widgetSide.complete(id: id, on: today))

        store.refreshFromDisk()
        XCTAssertTrue(store.habits.first?.isComplete(on: today) ?? false)
    }

    func testStoreToggleReturnsTheResultingState() {
        let store = HabitStore(storage: storage)
        let today = store.today()
        store.add(HabitTemplate.water.makeHabit(createdOn: today))
        guard let id = store.habits.first?.id else { return XCTFail("habit was not added") }

        XCTAssertTrue(store.toggle(id: id, on: today))
        XCTAssertFalse(store.toggle(id: id, on: today))
        XCTAssertEqual(store.habits.first?.totalCompletions, 0)
    }

    func testDeletingAHabitLeavesTheOthers() {
        let store = HabitStore(storage: storage)
        let today = store.today()
        store.add(HabitTemplate.quran.makeHabit(createdOn: today))
        store.add(HabitTemplate.reading.makeHabit(createdOn: today))
        guard let first = store.habits.first?.id else { return XCTFail("habits were not added") }

        store.delete(id: first)
        XCTAssertEqual(store.habits.count, 1)
        XCTAssertEqual(store.habits.first?.name, "Reading")
        XCTAssertEqual(HabitStore(storage: storage).habits.count, 1)
    }

    func testSettingsPersist() {
        let store = HabitStore(storage: storage)
        store.updateSettings { $0.dayStartHour = 4 }
        store.updateSettings { $0.haptics = false }
        XCTAssertEqual(HabitStore(storage: storage).settings.dayStartHour, 4)
        XCTAssertFalse(HabitStore(storage: storage).settings.haptics)
    }
}
