import Foundation

/// What today's step of a habit actually *is*.
///
/// Most habits need nothing here — ten pushups are ten pushups every day. Habits with
/// ordered content advance one step per completion, which is what makes "read one ayah
/// a day" work without ever skipping content on a missed day.
enum HabitSequence: Hashable, Sendable {
    /// The action is the same every day.
    case none
    /// Consecutive ayahs from a starting point, `start` being a 1-based index into the Quran.
    case quran(start: Int)
    /// Plain counting: page 1, page 2, … `unit` is singular and capitalised, e.g. "Page".
    case numbered(unit: String, start: Int)
}

extension HabitSequence: Codable {
    private enum CodingKeys: String, CodingKey {
        case kind, start, unit
    }

    private enum Kind: String, Codable {
        case none, quran, numbered
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decodeIfPresent(Kind.self, forKey: .kind)
        switch kind {
        case .quran:
            let start = try container.decodeIfPresent(Int.self, forKey: .start) ?? 1
            self = .quran(start: start)
        case .numbered:
            let unit = try container.decodeIfPresent(String.self, forKey: .unit) ?? "Step"
            let start = try container.decodeIfPresent(Int.self, forKey: .start) ?? 1
            self = .numbered(unit: unit, start: start)
        case .none, nil:
            // An unknown kind from a newer build degrades to a plain daily habit rather
            // than failing the whole document.
            self = .none
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .none:
            try container.encode(Kind.none, forKey: .kind)
        case .quran(let start):
            try container.encode(Kind.quran, forKey: .kind)
            try container.encode(start, forKey: .start)
        case .numbered(let unit, let start):
            try container.encode(Kind.numbered, forKey: .kind)
            try container.encode(unit, forKey: .unit)
            try container.encode(start, forKey: .start)
        }
    }
}

extension HabitSequence {
    var hasContent: Bool {
        if case .none = self { return false }
        return true
    }
}

/// A resolved step, ready to render. Deliberately presentation-shaped so both the app and
/// the widget draw the same thing without re-deriving anything.
struct SequenceItem: Hashable, Sendable {
    /// Short, uppercase-friendly locator, e.g. "AL-BAQARAH · 255".
    var reference: String
    /// The content itself, when the habit has any to show.
    var body: String?
    /// Optional second line — a translation.
    var translation: String?
    /// Arabic sets this so text lays out right to left.
    var isRightToLeft: Bool
    /// Position through the whole sequence, e.g. "255 of 6,236".
    var progress: String?

    init(
        reference: String,
        body: String? = nil,
        translation: String? = nil,
        isRightToLeft: Bool = false,
        progress: String? = nil
    ) {
        self.reference = reference
        self.body = body
        self.translation = translation
        self.isRightToLeft = isRightToLeft
        self.progress = progress
    }
}

/// Turns `(sequence, step)` into something renderable. The single place that knows how
/// each kind of content is laid out.
enum SequenceResolver {
    static func item(for sequence: HabitSequence, step: Int, includeTranslation: Bool = true) -> SequenceItem? {
        switch sequence {
        case .none:
            return nil

        case .quran(let start):
            let index = QuranLibrary.wrappedIndex(start: start, step: step)
            guard let location = QuranLibrary.shared.location(ofAyah: index) else { return nil }
            let reference = "\(location.surah.latinName.uppercased()) · \(location.ayah)"
            return SequenceItem(
                reference: reference,
                body: QuranLibrary.shared.arabic(at: index),
                translation: includeTranslation ? QuranLibrary.shared.translation(at: index) : nil,
                isRightToLeft: true,
                progress: "\(Self.grouped(index)) of \(Self.grouped(QuranLibrary.ayahCount))"
            )

        case .numbered(let unit, let start):
            let number = start + step
            return SequenceItem(
                reference: "\(unit.uppercased()) \(number)",
                progress: nil
            )
        }
    }

    private static let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()

    static func grouped(_ value: Int) -> String {
        formatter.string(from: NSNumber(value: value)) ?? String(value)
    }
}
