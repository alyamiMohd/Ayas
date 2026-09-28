import XCTest
@testable import Ayas

/// The behaviours from the product brief, asserted directly.
final class StreakTests: XCTestCase {
    private let utc: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        return calendar
    }()

    private let start = DayKey(year: 2026, month: 9, day: 28)

    private func makeHabit() -> Habit {
        HabitTemplate.quran.makeHabit(createdOn: start)
    }

    private func day(_ offset: Int) -> DayKey {
        start.adding(days: offset, calendar: utc)
    }

    func testFreshHabitHasNothing() {
        let habit = makeHabit()
        XCTAssertEqual(habit.currentStreak(asOf: start, calendar: utc), 0)
        XCTAssertEqual(habit.bestStreak(calendar: utc), 0)
        XCTAssertEqual(habit.totalCompletions, 0)
        XCTAssertFalse(habit.isComplete(on: start))
        XCTAssertEqual(habit.dueStep(on: start), 0)
    }

    func testCompletingTodayStartsAStreakOfOne() {
        var habit = makeHabit()
        XCTAssertTrue(habit.markComplete(on: start))
        XCTAssertTrue(habit.isComplete(on: start))
        XCTAssertEqual(habit.currentStreak(asOf: start, calendar: utc), 1)
        XCTAssertEqual(habit.totalCompletions, 1)
    }

    func testCompletingTwiceChangesNothing() {
        var habit = makeHabit()
        habit.markComplete(on: start)
        XCTAssertFalse(habit.markComplete(on: start), "second completion must be a no-op")
        XCTAssertEqual(habit.totalCompletions, 1)
        XCTAssertEqual(habit.currentStreak(asOf: start, calendar: utc), 1)
        XCTAssertEqual(habit.nextStep, 1, "the sequence must not advance twice")
    }

    func testThreeConsecutiveDays() {
        var habit = makeHabit()
        habit.markComplete(on: day(0))
        habit.markComplete(on: day(1))
        habit.markComplete(on: day(2))
        XCTAssertEqual(habit.currentStreak(asOf: day(2), calendar: utc), 3)
    }

    func testStreakSurvivesTheDayItIsStillPossibleToComplete() {
        var habit = makeHabit()
        habit.markComplete(on: day(0))
        habit.markComplete(on: day(1))
        // Today (day 2) is not done yet — the run should still read as 2, not 0.
        XCTAssertEqual(habit.currentStreak(asOf: day(2), calendar: utc), 2)
        XCTAssertFalse(habit.isComplete(on: day(2)))
    }

    func testStreakBreaksAfterAFullMissedDay() {
        var habit = makeHabit()
        habit.markComplete(on: day(0))
        habit.markComplete(on: day(1))
        // Day 2 missed entirely; by day 3 the run is gone.
        XCTAssertEqual(habit.currentStreak(asOf: day(3), calendar: utc), 0)
    }

    func testCompletionAfterAMissedDayStartsANewStreak() {
        var habit = makeHabit()
        habit.markComplete(on: day(0))
        habit.markComplete(on: day(1))
        habit.markComplete(on: day(3))
        XCTAssertEqual(habit.currentStreak(asOf: day(3), calendar: utc), 1, "new run, not a continuation")
        XCTAssertEqual(habit.bestStreak(calendar: utc), 2, "the old run is remembered as the best")
        XCTAssertEqual(habit.totalCompletions, 3)
    }

    func testUndoingTodayRemovesItAndRewindsTheSequence() {
        var habit = makeHabit()
        habit.markComplete(on: day(0))
        habit.markComplete(on: day(1))
        XCTAssertEqual(habit.nextStep, 2)

        XCTAssertTrue(habit.clearCompletion(on: day(1)))
        XCTAssertEqual(habit.nextStep, 1, "the sequence steps back with the completion")
        XCTAssertEqual(habit.currentStreak(asOf: day(1), calendar: utc), 1)
        XCTAssertFalse(habit.clearCompletion(on: day(1)), "clearing twice is a no-op")
    }

    func testStreakRunsAcrossAMonthBoundary() {
        var habit = makeHabit()
        let last = DayKey(year: 2026, month: 8, day: 30)
        for offset in 0...3 {
            habit.markComplete(on: last.adding(days: offset, calendar: utc))
        }
        // 30, 31 August, 1, 2 September.
        XCTAssertEqual(
            habit.currentStreak(asOf: DayKey(year: 2026, month: 9, day: 2), calendar: utc),
            4
        )
    }

    func testCompletionsStaySortedWhenRecordedOutOfOrder() {
        var habit = makeHabit()
        habit.markComplete(on: day(2))
        // Travelling west can make "today" earlier than a day already recorded.
        habit.markComplete(on: day(0))
        habit.markComplete(on: day(1))
        XCTAssertEqual(habit.completions.map(\.day), [day(0), day(1), day(2)])
        XCTAssertEqual(habit.currentStreak(asOf: day(2), calendar: utc), 3)
    }

    func testRecentDaysEndsOnToday() {
        var habit = makeHabit()
        habit.markComplete(on: day(-1))
        habit.markComplete(on: day(0))
        let marks = habit.recentDays(endingOn: day(0), count: 7, calendar: utc)
        XCTAssertEqual(marks.count, 7)
        XCTAssertEqual(marks.last?.day, day(0))
        XCTAssertEqual(marks.map(\.done), [false, false, false, false, false, true, true])
    }

    func testStreakLabelReads() {
        var habit = makeHabit()
        XCTAssertEqual(HabitSnapshot(habit: habit, day: start, calendar: utc).streakLabel, "No streak yet")
        habit.markComplete(on: start)
        XCTAssertEqual(HabitSnapshot(habit: habit, day: start, calendar: utc).streakLabel, "1 day")
        habit.markComplete(on: day(1))
        XCTAssertEqual(HabitSnapshot(habit: habit, day: day(1), calendar: utc).streakLabel, "2 days")
    }
}
