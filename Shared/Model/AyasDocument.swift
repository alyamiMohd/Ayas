import Foundation

/// Everything the app remembers, in one value. The app and the widget both read and write
/// this single document, which is what keeps them from ever disagreeing.
struct AyasDocument: Codable, Equatable, Sendable {
    static let currentVersion = 1

    var version: Int
    var habits: [Habit]
    var settings: Settings

    init(version: Int = AyasDocument.currentVersion, habits: [Habit] = [], settings: Settings = Settings()) {
        self.version = version
        self.habits = habits
        self.settings = settings
    }

    /// Missing keys fall back to defaults so a document written by an older build still
    /// opens after an app update.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        version = try container.decodeIfPresent(Int.self, forKey: .version) ?? AyasDocument.currentVersion
        habits = try container.decodeIfPresent([Habit].self, forKey: .habits) ?? []
        settings = try container.decodeIfPresent(Settings.self, forKey: .settings) ?? Settings()
    }
}

struct Settings: Codable, Equatable, Sendable {
    var appearance: AppearanceChoice
    /// Hour at which a new day begins, 0–4. Lets a late-night completion count for the
    /// day it feels like rather than the one the clock says.
    var dayStartHour: Int
    var haptics: Bool
    /// Show an English translation beneath Arabic content.
    var showTranslation: Bool

    init(
        appearance: AppearanceChoice = .system,
        dayStartHour: Int = 0,
        haptics: Bool = true,
        showTranslation: Bool = true
    ) {
        self.appearance = appearance
        self.dayStartHour = dayStartHour
        self.haptics = haptics
        self.showTranslation = showTranslation
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        appearance = try container.decodeIfPresent(AppearanceChoice.self, forKey: .appearance) ?? .system
        let hour = try container.decodeIfPresent(Int.self, forKey: .dayStartHour) ?? 0
        dayStartHour = min(max(hour, 0), 4)
        haptics = try container.decodeIfPresent(Bool.self, forKey: .haptics) ?? true
        showTranslation = try container.decodeIfPresent(Bool.self, forKey: .showTranslation) ?? true
    }
}

enum AppearanceChoice: String, Codable, CaseIterable, Sendable {
    case system
    case light
    case dark

    var label: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = AppearanceChoice(rawValue: raw) ?? .system
    }
}
