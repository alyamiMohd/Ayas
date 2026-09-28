import SwiftUI
import WidgetKit

/// The Home Screen widget — the environmental cue the whole app is built around.
///
/// Configured through an App Intent, so each widget instance points at its own habit and
/// several can sit side by side.
struct HabitWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: WidgetKinds.habit,
            intent: SelectHabitIntent.self,
            provider: HabitTimelineProvider()
        ) { entry in
            HabitWidgetView(entry: entry)
        }
        .configurationDisplayName("Habit")
        .description("Keeps one tiny action where you already look.")
        .supportedFamilies([.systemSmall, .systemMedium])
        // The face draws its own margins; the default insets are too generous for this layout.
        .contentMarginsDisabled()
    }
}
