import Foundation

/// A civil calendar day — not an instant. Stored as `yyyymmdd`.
///
/// Completions are recorded as civil days so that travelling between timezones can
/// never retroactively move a past completion into a different day. An instant would
/// drift; "28 September" does not.
struct DayKey: Hashable, Comparable, Sendable, CustomStringConvertible {
    let rawValue: Int

    init(rawValue: Int) {
        self.rawValue = rawValue
    }

    init(year: Int, month: Int, day: Int) {
        rawValue = year * 10_000 + month * 100 + day
    }

    /// The habit-day containing `date`.
    ///
    /// `dayStartHour` lets a day begin after midnight, so an ayah read at 00:30 still
    /// counts for the day the reader thinks of as "tonight".
    ///
    /// Compares the wall-clock hour rather than subtracting hours from the instant: on a
    /// spring-forward morning the two are not the same, and absolute arithmetic would put
    /// the boundary on the wrong side of the date.
    init(_ date: Date, calendar: Calendar = .current, dayStartHour: Int = 0) {
        let parts = calendar.dateComponents([.year, .month, .day, .hour], from: date)
        let civil = DayKey(year: parts.year ?? 1970, month: parts.month ?? 1, day: parts.day ?? 1)
        self = (parts.hour ?? 0) < dayStartHour ? civil.adding(days: -1, calendar: calendar) : civil
    }

    var year: Int { rawValue / 10_000 }
    var month: Int { (rawValue / 100) % 100 }
    var day: Int { rawValue % 100 }

    var description: String { String(format: "%04d-%02d-%02d", year, month, day) }

    static func < (lhs: DayKey, rhs: DayKey) -> Bool { lhs.rawValue < rhs.rawValue }

    private static func civilDay(of date: Date, calendar: Calendar) -> DayKey {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return DayKey(year: parts.year ?? 1970, month: parts.month ?? 1, day: parts.day ?? 1)
    }

    /// Midday anchor for this day. Noon keeps day arithmetic clear of DST transitions,
    /// which only ever move clocks by an hour or two around midnight.
    func noon(calendar: Calendar = .current) -> Date {
        var parts = DateComponents()
        parts.year = year
        parts.month = month
        parts.day = day
        parts.hour = 12
        return calendar.date(from: parts) ?? Date(timeIntervalSince1970: 0)
    }

    /// The instant this habit-day begins.
    func startInstant(dayStartHour: Int, calendar: Calendar = .current) -> Date {
        var parts = DateComponents()
        parts.year = year
        parts.month = month
        parts.day = day
        parts.hour = dayStartHour
        // On a spring-forward date the named hour may not exist; Calendar resolves it forward.
        return calendar.date(from: parts) ?? noon(calendar: calendar)
    }

    func adding(days: Int, calendar: Calendar = .current) -> DayKey {
        guard days != 0 else { return self }
        let moved = calendar.date(byAdding: .day, value: days, to: noon(calendar: calendar))
        return DayKey.civilDay(of: moved ?? noon(calendar: calendar), calendar: calendar)
    }

    var previous: DayKey { adding(days: -1) }
    var next: DayKey { adding(days: 1) }

    /// Whole days from `other` to `self`. Negative when `self` is earlier.
    func days(since other: DayKey, calendar: Calendar = .current) -> Int {
        let span = calendar.dateComponents(
            [.day],
            from: other.noon(calendar: calendar),
            to: noon(calendar: calendar)
        )
        return span.day ?? 0
    }

    func isConsecutive(after other: DayKey, calendar: Calendar = .current) -> Bool {
        days(since: other, calendar: calendar) == 1
    }
}

/// Encoded as a bare integer so the stored document stays small and readable.
extension DayKey: Codable {
    init(from decoder: Decoder) throws {
        rawValue = try decoder.singleValueContainer().decode(Int.self)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

/// Resolves "what day is it" and "when does the next day begin" from one place, so the
/// app and the widget never disagree about where a day boundary sits.
enum DayClock {
    static func today(dayStartHour: Int, now: Date = Date(), calendar: Calendar = .current) -> DayKey {
        DayKey(now, calendar: calendar, dayStartHour: dayStartHour)
    }

    /// The next day boundary strictly after `now`.
    static func nextBoundary(
        after now: Date,
        dayStartHour: Int,
        calendar: Calendar = .current
    ) -> Date {
        let current = today(dayStartHour: dayStartHour, now: now, calendar: calendar)
        var boundary = current.next.startInstant(dayStartHour: dayStartHour, calendar: calendar)
        // Guard against a boundary that lands on or before `now` (possible around a DST
        // shift): step forward a day at a time until it is genuinely in the future.
        var cursor = current.next
        var guardCount = 0
        while boundary <= now, guardCount < 4 {
            cursor = cursor.next
            boundary = cursor.startInstant(dayStartHour: dayStartHour, calendar: calendar)
            guardCount += 1
        }
        return boundary
    }
}
