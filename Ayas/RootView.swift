import Combine
import SwiftUI
import UIKit
import WidgetKit

/// Holds navigation for the whole app: one stack, three sheets. The system navigation bar is
/// hidden throughout — each screen draws its own header instead.
struct RootView: View {
    @Environment(HabitStore.self) private var store
    @Environment(\.scenePhase) private var scenePhase

    @State private var path: [UUID] = []
    @State private var sheet: SheetKind?

    private enum SheetKind: Identifiable {
        case create(templateID: String?)
        case edit(habitID: UUID)
        case settings

        var id: String {
            switch self {
            case .create(let templateID): return "create-\(templateID ?? "blank")"
            case .edit(let habitID): return "edit-\(habitID.uuidString)"
            case .settings: return "settings"
            }
        }
    }

    var body: some View {
        NavigationStack(path: $path) {
            TodayView(
                onOpen: { path.append($0) },
                onCreate: { sheet = .create(templateID: nil) },
                onQuickStart: { sheet = .create(templateID: HabitTemplate.quran.id) },
                onSettings: { sheet = .settings }
            )
            .navigationDestination(for: UUID.self) { habitID in
                HabitDetailView(
                    habitID: habitID,
                    onBack: { pop() },
                    onEdit: { sheet = .edit(habitID: habitID) }
                )
            }
        }
        .tint(Palette.ink)
        .sheet(item: $sheet) { kind in
            sheetContent(kind)
        }
        .preferredColorScheme(store.settings.appearance.colorScheme)
        .onChange(of: scenePhase) { _, phase in
            // The widget may have completed something while the app was away.
            if phase == .active { store.refreshFromDisk() }
        }
        .onOpenURL { url in
            guard let habitID = DeepLink.habitID(from: url) else { return }
            store.refreshFromDisk()
            guard store.habit(id: habitID) != nil else { return }
            path = [habitID]
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
            // Midnight passed, or the device crossed a timezone: today's answer changed.
            store.refreshFromDisk()
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    @ViewBuilder
    private func sheetContent(_ kind: SheetKind) -> some View {
        switch kind {
        case .create(let templateID):
            HabitEditorView(
                mode: .create(HabitTemplate.all.first { $0.id == templateID }),
                onSave: { habit in
                    store.add(habit)
                    Haptics.selection(enabled: store.settings.haptics)
                }
            )

        case .edit(let habitID):
            if let habit = store.habit(id: habitID) {
                HabitEditorView(
                    mode: .edit(habit),
                    onSave: { store.update($0) },
                    onDelete: {
                        store.delete(id: habitID)
                        pop()
                    }
                )
            }

        case .settings:
            SettingsView()
        }
    }

    private func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
}
