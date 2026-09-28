import Foundation

/// Starting points offered when creating a habit. Every one of them is small enough to do
/// on the worst day of the week, which is the whole point.
struct HabitTemplate: Identifiable, Hashable, Sendable {
    var id: String
    var name: String
    var action: String
    var glyph: Glyph
    var accent: AccentKey
    var sequence: HabitSequence

    func makeHabit(createdOn day: DayKey) -> Habit {
        Habit(
            name: name,
            action: action,
            glyph: glyph,
            accent: accent,
            sequence: sequence,
            createdOn: day
        )
    }
}

extension HabitTemplate {
    static let quran = HabitTemplate(
        id: "quran",
        name: "Quran",
        action: "Read one ayah",
        glyph: .book,
        accent: .olive,
        sequence: .quran(start: 1)
    )

    static let reading = HabitTemplate(
        id: "reading",
        name: "Reading",
        action: "Read one page",
        glyph: .pen,
        accent: .sand,
        sequence: .numbered(unit: "Page", start: 1)
    )

    static let strength = HabitTemplate(
        id: "strength",
        name: "Strength",
        action: "Ten pushups",
        glyph: .strength,
        accent: .ember,
        sequence: .none
    )

    static let stillness = HabitTemplate(
        id: "stillness",
        name: "Stillness",
        action: "Two minutes of quiet",
        glyph: .moon,
        accent: .indigo,
        sequence: .none
    )

    static let water = HabitTemplate(
        id: "water",
        name: "Water",
        action: "One glass, first thing",
        glyph: .drop,
        accent: .teal,
        sequence: .none
    )

    static let all: [HabitTemplate] = [quran, reading, strength, stillness, water]
}
