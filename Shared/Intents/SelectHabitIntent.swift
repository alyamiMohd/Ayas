import AppIntents
import WidgetKit

/// Which habit a given widget shows. Each widget on the Home Screen carries its own
/// configuration, so three habits can sit side by side as three separate widgets.
///
/// The parameter is optional on purpose: a freshly dropped widget shows the first habit
/// rather than an empty configuration prompt.
struct SelectHabitIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Choose Habit" }

    static var description: IntentDescription {
        IntentDescription("Pick which habit this widget keeps in front of you.")
    }

    @Parameter(title: "Habit")
    var habit: HabitEntity?

    init() {}

    init(habit: HabitEntity?) {
        self.habit = habit
    }
}
