import XCTest
@testable import Ayas

/// Day boundaries are where a habit tracker quietly goes wrong, so they get tested directly.
final class DayKeyTests: XCTestCase {
    private let utc: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        return calendar
    }()

    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 12, _ minute: Int = 0, calendar: Calendar? = nil) -> Date {
        var parts = DateComponents()
        parts.year = year
        parts.month = month
        parts.day = day
        parts.hour = hour
        parts.minute = minute
        return (calendar ?? utc).date(from: parts) ?? Date()
    }

    func testRawValueLayout() {
        let day = DayKey(year: 2026, month: 9, day: 28)
        XCTAssertEqual(day.rawValue, 20_260_928)
        XCTAssertEqual(day.year, 2026)
        XCTAssertEqual(day.month, 9)
        XCTAssertEqual(day.day, 28)
        XCTAssertEqual(day.description, "2026-09-28")
    }

    func testMidnightRolloverUsesCivilDate() {
        let justAfterMidnight = date(2026, 9, 29, 0, 30)
        XCTAssertEqual(
            DayKey(justAfterMidnight, calendar: utc, dayStartHour: 0),
            DayKey(year: 2026, month: 9, day: 29)
        )
    }

    func testLateNightCountsForPreviousDayWhenDayStartsLater() {
        let justAfterMidnight = date(2026, 9, 29, 0, 30)
        // With the day starting at 2 AM, 00:30 still belongs to the 28th.
        XCTAssertEqual(
            DayKey(justAfterMidnight, calendar: utc, dayStartHour: 2),
            DayKey(year: 2026, month: 9, day: 28)
        )
        // And 02:30 has moved on to the 29th.
        XCTAssertEqual(
            DayKey(date(2026, 9, 29, 2, 30), calendar: utc, dayStartHour: 2),
            DayKey(year: 2026, month: 9, day: 29)
        )
    }

    func testDayArithmeticCrossesMonthAndYear() {
        XCTAssertEqual(
            DayKey(year: 2026, month: 9, day: 30).adding(days: 1, calendar: utc),
            DayKey(year: 2026, month: 10, day: 1)
        )
        XCTAssertEqual(
            DayKey(year: 2026, month: 12, day: 31).adding(days: 1, calendar: utc),
            DayKey(year: 2027, month: 1, day: 1)
        )
        XCTAssertEqual(
            DayKey(year: 2027, month: 1, day: 1).adding(days: -1, calendar: utc),
            DayKey(year: 2026, month: 12, day: 31)
        )
        XCTAssertEqual(
            DayKey(year: 2028, month: 2, day: 28).adding(days: 1, calendar: utc),
            DayKey(year: 2028, month: 2, day: 29),
            "2028 is a leap year"
        )
    }

    func testConsecutiveAcrossMonthBoundary() {
        let last = DayKey(year: 2026, month: 8, day: 31)
        let first = DayKey(year: 2026, month: 9, day: 1)
        XCTAssertTrue(first.isConsecutive(after: last, calendar: utc))
        XCTAssertFalse(last.isConsecutive(after: first, calendar: utc))
        XCTAssertEqual(first.days(since: last, calendar: utc), 1)
        XCTAssertEqual(last.days(since: first, calendar: utc), -1)
    }

    func testNextBoundaryIsAlwaysInTheFuture() {
        for hour in 0...4 {
            for probe in [0, 1, 2, 3, 5, 12, 23] {
                let now = date(2026, 9, 28, probe, 0)
                let boundary = DayClock.nextBoundary(after: now, dayStartHour: hour, calendar: utc)
                XCTAssertGreaterThan(boundary, now, "hour \(hour), probe \(probe)")
                // Crossing that boundary must land on a different habit-day.
                let before = DayKey(now, calendar: utc, dayStartHour: hour)
                let after = DayKey(boundary, calendar: utc, dayStartHour: hour)
                XCTAssertEqual(after, before.next, "hour \(hour), probe \(probe)")
            }
        }
    }

    func testBoundaryAcrossDaylightSavingTransition() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/London") ?? .gmt
        // Clocks go forward at 01:00 on 29 March 2026 in the UK.
        let evening = date(2026, 3, 28, 23, 0, calendar: calendar)
        let boundary = DayClock.nextBoundary(after: evening, dayStartHour: 2, calendar: calendar)
        XCTAssertGreaterThan(boundary, evening)
        XCTAssertEqual(
            DayKey(boundary, calendar: calendar, dayStartHour: 2),
            DayKey(year: 2026, month: 3, day: 29)
        )
    }

    func testCodableRoundTripsAsBareInteger() throws {
        let day = DayKey(year: 2026, month: 9, day: 28)
        let data = try JSONEncoder().encode(day)
        XCTAssertEqual(String(data: data, encoding: .utf8), "20260928")
        XCTAssertEqual(try JSONDecoder().decode(DayKey.self, from: data), day)
    }
}
