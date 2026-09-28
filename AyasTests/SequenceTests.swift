import XCTest
@testable import Ayas

/// The Quran dataset and the rule that makes "read one ayah a day" work: position follows
/// completions, never the calendar.
final class SequenceTests: XCTestCase {
    private let utc: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        return calendar
    }()

    private let start = DayKey(year: 2026, month: 9, day: 28)

    func testDatasetIsBundledAndComplete() throws {
        let library = QuranLibrary.shared
        try XCTSkipUnless(library.isAvailable, "Quran resources are not in this bundle")

        XCTAssertEqual(library.surahs.count, 114)
        XCTAssertEqual(library.surahs.reduce(0) { $0 + $1.ayahCount }, QuranLibrary.ayahCount)
        XCTAssertEqual(library.surahs.first?.ayahCount, 7, "Al-Fatihah has seven ayahs")
        XCTAssertEqual(library.surahs.last?.ayahCount, 6, "An-Nas has six")
    }

    func testKnownReferencesMapToTheRightGlobalIndex() throws {
        let library = QuranLibrary.shared
        try XCTSkipUnless(library.isAvailable)

        XCTAssertEqual(library.globalIndex(surah: 1, ayah: 1), 1)
        XCTAssertEqual(library.globalIndex(surah: 2, ayah: 1), 8, "Al-Baqarah starts after Al-Fatihah's seven")
        XCTAssertEqual(library.globalIndex(surah: 2, ayah: 255), 262, "Ayat al-Kursi")
        XCTAssertEqual(library.globalIndex(surah: 114, ayah: 6), QuranLibrary.ayahCount)

        XCTAssertNil(library.globalIndex(surah: 1, ayah: 8), "Al-Fatihah has no eighth ayah")
        XCTAssertNil(library.globalIndex(surah: 115, ayah: 1))
    }

    func testLocationRoundTripsForEveryAyah() throws {
        let library = QuranLibrary.shared
        try XCTSkipUnless(library.isAvailable)

        for index in 1...QuranLibrary.ayahCount {
            guard let location = library.location(ofAyah: index) else {
                return XCTFail("no location for \(index)")
            }
            XCTAssertEqual(library.globalIndex(surah: location.surah.number, ayah: location.ayah), index)
        }
    }

    func testTextReadsBackFromTheOffsetIndex() throws {
        let library = QuranLibrary.shared
        try XCTSkipUnless(library.isAvailable)

        for index in [1, 8, 262, 3000, QuranLibrary.ayahCount] {
            let arabic = library.arabic(at: index)
            XCTAssertNotNil(arabic, "no Arabic at \(index)")
            XCTAssertFalse(arabic?.isEmpty ?? true)
            XCTAssertFalse(arabic?.contains("\n") ?? true, "records must not span lines")
        }

        XCTAssertNil(library.arabic(at: 0), "indices are one-based")
        XCTAssertNil(library.arabic(at: QuranLibrary.ayahCount + 1))

        let ayatAlKursi = library.arabic(at: 262) ?? ""
        XCTAssertGreaterThan(ayatAlKursi.count, 100, "2:255 is a long ayah")
        XCTAssertNotNil(library.translation(at: 1))
    }

    func testBasmalahIsStrippedFromLaterSurahOpenings() throws {
        let library = QuranLibrary.shared
        try XCTSkipUnless(library.isAvailable)

        let basmalah = library.arabic(at: 1) ?? ""
        XCTAssertFalse(basmalah.isEmpty)

        // Surah 2 opens with the muqatta'at alone, not with the basmalah prepended.
        let baqarahOpening = library.arabic(at: 8) ?? ""
        XCTAssertFalse(baqarahOpening.hasPrefix(basmalah))
        XCTAssertLessThan(baqarahOpening.count, basmalah.count)
    }

    func testIndexWrapsAtTheEndOfTheQuran() {
        XCTAssertEqual(QuranLibrary.wrappedIndex(start: 1, step: 0), 1)
        XCTAssertEqual(QuranLibrary.wrappedIndex(start: 1, step: 6), 7)
        XCTAssertEqual(QuranLibrary.wrappedIndex(start: 1, step: QuranLibrary.ayahCount - 1), QuranLibrary.ayahCount)
        XCTAssertEqual(QuranLibrary.wrappedIndex(start: 1, step: QuranLibrary.ayahCount), 1, "starts again")
        XCTAssertEqual(QuranLibrary.wrappedIndex(start: QuranLibrary.ayahCount, step: 1), 1)
    }

    func testPositionFollowsCompletionsNotDates() {
        var habit = HabitTemplate.quran.makeHabit(createdOn: start)
        XCTAssertEqual(habit.dueStep(on: start), 0)

        habit.markComplete(on: start)
        // Next day: one step on.
        XCTAssertEqual(habit.dueStep(on: start.adding(days: 1, calendar: utc)), 1)
        // Skip several days without completing — the step must not run ahead, or ayahs would
        // be silently skipped.
        XCTAssertEqual(habit.dueStep(on: start.adding(days: 9, calendar: utc)), 1)
    }

    func testCompletedDayKeepsShowingWhatWasRead() {
        var habit = HabitTemplate.quran.makeHabit(createdOn: start)
        habit.markComplete(on: start)
        XCTAssertEqual(habit.dueStep(on: start), 0, "today still shows the ayah that was read")
        XCTAssertEqual(habit.completion(on: start)?.step, 0)
    }

    func testQuranResolverProducesAReference() throws {
        try XCTSkipUnless(QuranLibrary.shared.isAvailable)

        let item = SequenceResolver.item(for: .quran(start: 262), step: 0)
        XCTAssertNotNil(item)
        XCTAssertTrue(item?.reference.contains("255") ?? false, "got \(item?.reference ?? "nil")")
        XCTAssertTrue(item?.isRightToLeft ?? false)
        XCTAssertNotNil(item?.body)
        // Grouping separators are locale-dependent, so check the shape rather than the string.
        XCTAssertTrue(item?.progress?.hasPrefix("262 of") ?? false, "got \(item?.progress ?? "nil")")
    }

    func testNumberedSequenceCountsUp() {
        let first = SequenceResolver.item(for: .numbered(unit: "Page", start: 12), step: 0)
        XCTAssertEqual(first?.reference, "PAGE 12")
        XCTAssertNil(first?.body)

        let later = SequenceResolver.item(for: .numbered(unit: "Page", start: 12), step: 5)
        XCTAssertEqual(later?.reference, "PAGE 17")
    }

    func testPlainHabitsHaveNoItem() {
        XCTAssertNil(SequenceResolver.item(for: .none, step: 0))
        XCTAssertFalse(HabitSequence.none.hasContent)
        XCTAssertTrue(HabitSequence.quran(start: 1).hasContent)
    }
}
