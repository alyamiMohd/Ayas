import Foundation

/// One tiny daily action.
///
/// A habit owns its completion history; everything else (streak, position in a sequence,
/// today's state) is derived from that history so there is only ever one fact to store.
struct Habit: Identifiable, Hashable, Codable, Sendable {
    var id: UUID
    var name: String
    var action: String
    var glyph: Glyph
    var accent: AccentKey
    var sequence: HabitSequence
    var createdOn: DayKey
    /// Ascending by day, at most one entry per day.
    var completions: [Completion]

    init(
        id: UUID = UUID(),
        name: String,
        action: String,
        glyph: Glyph = .leaf,
        accent: AccentKey = .ember,
        sequence: HabitSequence = .none,
        createdOn: DayKey,
        completions: [Completion] = []
    ) {
        self.id = id
        self.name = name
        self.action = action
        self.glyph = glyph
        self.accent = accent
        self.sequence = sequence
        self.createdOn = createdOn
        self.completions = completions
    }
}

/// A single day's completion, remembering which step of the sequence was done.
struct Completion: Hashable, Codable, Sendable {
    var day: DayKey
    /// Zero-based offset into the habit's sequence.
    var step: Int
}

/// One cell of the week strip.
struct DayMark: Identifiable, Hashable, Sendable {
    var day: DayKey
    var done: Bool
    var id: Int { day.rawValue }
}

// MARK: - Derived state

extension Habit {
    var totalCompletions: Int { completions.count }

    /// The step the sequence has advanced to. Position follows completions, not the
    /// calendar: missing a day must never skip an ayah.
    var nextStep: Int { completions.count }

    func completion(on day: DayKey) -> Completion? {
        completions.first { $0.day == day }
    }

    func isComplete(on day: DayKey) -> Bool {
        completion(on: day) != nil
    }

    /// The step due on `day` — the one already done if it is done, otherwise the next one.
    func dueStep(on day: DayKey) -> Int {
        completion(on: day)?.step ?? nextStep
    }

    /// Consecutive days ending today, or ending yesterday while today is still open.
    ///
    /// Yesterday counts as the anchor so a streak does not read as broken during the day
    /// you are still able to complete. Once a whole day passes unmarked the streak is gone,
    /// and the next completion starts again at 1.
    func currentStreak(asOf today: DayKey, calendar: Calendar = .current) -> Int {
        let days = Set(completions.map(\.day))
        guard !days.isEmpty else { return 0 }

        let anchor: DayKey
        if days.contains(today) {
            anchor = today
        } else if days.contains(today.previous) {
            anchor = today.previous
        } else {
            return 0
        }

        var length = 0
        var cursor = anchor
        while days.contains(cursor) {
            length += 1
            cursor = cursor.adding(days: -1, calendar: calendar)
        }
        return length
    }

    /// Longest run of consecutive days ever recorded.
    func bestStreak(calendar: Calendar = .current) -> Int {
        let days = completions.map(\.day).sorted()
        guard !days.isEmpty else { return 0 }

        var best = 1
        var run = 1
        for index in 1..<days.count {
            run = days[index].isConsecutive(after: days[index - 1], calendar: calendar) ? run + 1 : 1
            best = max(best, run)
        }
        return best
    }

    /// Most recent `count` days, oldest first.
    func recentDays(endingOn today: DayKey, count: Int, calendar: Calendar = .current) -> [DayMark] {
        let days = Set(completions.map(\.day))
        return (0..<count).reversed().map { offset in
            let day = today.adding(days: -offset, calendar: calendar)
            return DayMark(day: day, done: days.contains(day))
        }
    }
}

// MARK: - Mutation

extension Habit {
    /// Idempotent: completing an already-completed day changes nothing, so a double tap
    /// can never inflate a streak or advance the sequence twice.
    @discardableResult
    mutating func markComplete(on day: DayKey) -> Bool {
        guard !isComplete(on: day) else { return false }
        let entry = Completion(day: day, step: nextStep)
        let insertion = completions.firstIndex { $0.day > day } ?? completions.endIndex
        completions.insert(entry, at: insertion)
        return true
    }

    @discardableResult
    mutating func clearCompletion(on day: DayKey) -> Bool {
        guard let index = completions.firstIndex(where: { $0.day == day }) else { return false }
        completions.remove(at: index)
        return true
    }
}

// MARK: - Presentation choices

/// A quiet mark rather than an icon. Monochrome, tinted with the habit's accent.
enum Glyph: String, CaseIterable, Codable, Sendable {
    case book
    case moon
    case leaf
    case drop
    case sun
    case heart
    case walk
    case strength
    case pen
    case cup
    case wind
    case star

    var symbolName: String {
        switch self {
        case .book: return "book.closed"
        case .moon: return "moon"
        case .leaf: return "leaf"
        case .drop: return "drop"
        case .sun: return "sun.max"
        case .heart: return "heart"
        case .walk: return "figure.walk"
        case .strength: return "dumbbell"
        case .pen: return "pencil"
        case .cup: return "cup.and.saucer"
        case .wind: return "wind"
        case .star: return "sparkles"
        }
    }

    /// Tolerates values written by a newer build.
    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = Glyph(rawValue: raw) ?? .leaf
    }
}

enum AccentKey: String, CaseIterable, Codable, Sendable {
    case ember
    case olive
    case indigo
    case rose
    case sand
    case teal

    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = AccentKey(rawValue: raw) ?? .ember
    }
}
