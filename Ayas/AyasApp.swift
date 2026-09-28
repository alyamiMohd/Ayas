import SwiftUI

@main
struct AyasApp: App {
    /// One store for the process, shared with the widget through the app group document.
    @State private var store = HabitStore.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
        }
    }
}
