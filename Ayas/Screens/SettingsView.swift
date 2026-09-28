import SwiftUI

/// Only what someone might actually need to change. Four rows and a footer.
struct SettingsView: View {
    @Environment(HabitStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var confirmingErase = false

    private var settings: Settings { store.settings }

    var body: some View {
        ZStack {
            CanvasBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: Space.roomy) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("Settings")
                            .font(TypeScale.screenTitle)
                            .foregroundStyle(Palette.ink)
                        Spacer()
                        Button("Done") { dismiss() }
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Palette.inkSoft)
                    }

                    appearance
                    dayStart
                    translation
                    haptics
                    footer

                    Spacer(minLength: Space.regular)
                }
                .padding(.horizontal, Space.gutter)
                .padding(.top, Space.regular)
            }
            .scrollIndicators(.hidden)
        }
        .presentationDragIndicator(.hidden)
    }

    private var appearance: some View {
        VStack(alignment: .leading, spacing: Space.snug) {
            SectionLabel(text: "Appearance")
            HStack(spacing: Space.tight) {
                ForEach(AppearanceChoice.allCases, id: \.self) { choice in
                    let isSelected = settings.appearance == choice
                    Button {
                        Haptics.selection(enabled: settings.haptics)
                        withAnimation(Motion.soft) {
                            store.updateSettings { $0.appearance = choice }
                        }
                    } label: {
                        Text(choice.label)
                            .font(.system(size: 13, weight: isSelected ? .medium : .regular))
                            .foregroundStyle(isSelected ? Palette.onAccent : Palette.inkSoft)
                            .padding(.vertical, 9)
                            .frame(maxWidth: .infinity)
                            .background(Capsule().fill(isSelected ? Palette.ink : Palette.canvasLow))
                    }
                    .buttonStyle(PressableStyle(scale: 0.97))
                }
            }
        }
    }

    private var dayStart: some View {
        VStack(alignment: .leading, spacing: Space.snug) {
            SectionLabel(text: "A new day begins at")
            HStack(spacing: Space.tight) {
                ForEach(0...4, id: \.self) { hour in
                    let isSelected = settings.dayStartHour == hour
                    Button {
                        Haptics.selection(enabled: settings.haptics)
                        withAnimation(Motion.soft) {
                            store.updateSettings { $0.dayStartHour = hour }
                        }
                    } label: {
                        Text(hour == 0 ? "12" : "\(hour)")
                            .font(.system(size: 13, weight: isSelected ? .medium : .regular))
                            .foregroundStyle(isSelected ? Palette.onAccent : Palette.inkSoft)
                            .padding(.vertical, 9)
                            .frame(maxWidth: .infinity)
                            .background(Capsule().fill(isSelected ? Palette.ink : Palette.canvasLow))
                    }
                    .buttonStyle(PressableStyle(scale: 0.97))
                }
            }
            Text(settings.dayStartHour == 0
                 ? "Midnight. Anything after that counts for the new day."
                 : "\(settings.dayStartHour) AM. Finishing late at night still counts for the day before.")
                .font(TypeScale.caption)
                .foregroundStyle(Palette.inkFaint)
        }
    }

    private var translation: some View {
        ToggleRow(
            title: "Show translation",
            caption: "English alongside the Arabic.",
            isOn: settings.showTranslation
        ) {
            store.updateSettings { $0.showTranslation.toggle() }
        }
    }

    private var haptics: some View {
        ToggleRow(
            title: "Haptics",
            caption: "A soft tap when something is done.",
            isOn: settings.haptics
        ) {
            store.updateSettings { $0.haptics.toggle() }
        }
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: Space.snug) {
            Hairline()

            if !store.isSharedWithWidget {
                Text("The widget cannot reach this device's shared storage, so it will not stay in step with the app. Check that the App Groups capability is enabled for both targets with a matching group identifier.")
                    .font(TypeScale.caption)
                    .foregroundStyle(AccentKey.rose.color)
                    .padding(.top, Space.tight)
            }

            Text("Ayas · one tiny thing a day")
                .font(TypeScale.caption)
                .foregroundStyle(Palette.inkFaint)
                .padding(.top, Space.tight)

            Text("Quran text: Uthmani script with the Saheeh International translation, bundled with the app. Nothing leaves this device.")
                .font(TypeScale.caption)
                .foregroundStyle(Palette.inkFaint)
                .fixedSize(horizontal: false, vertical: true)

            if confirmingErase {
                VStack(alignment: .leading, spacing: Space.snug) {
                    Text("Erase every habit and all history?")
                        .font(TypeScale.bodySmall)
                        .foregroundStyle(Palette.ink)
                    HStack(spacing: Space.regular) {
                        Button("Erase everything") {
                            store.eraseEverything()
                            dismiss()
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AccentKey.rose.color)

                        Button("Cancel") {
                            withAnimation(Motion.soft) { confirmingErase = false }
                        }
                        .font(TypeScale.bodySmall)
                        .foregroundStyle(Palette.inkFaint)
                    }
                }
                .padding(.top, Space.snug)
            } else {
                Button("Erase all data") {
                    withAnimation(Motion.soft) { confirmingErase = true }
                }
                .font(TypeScale.caption)
                .foregroundStyle(Palette.inkFaint)
                .padding(.top, Space.tight)
            }
        }
    }
}

/// A switch without the system's blue. Reads as a line of text you can tap.
private struct ToggleRow: View {
    var title: String
    var caption: String
    var isOn: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: Space.regular) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(TypeScale.body)
                        .foregroundStyle(Palette.ink)
                    Text(caption)
                        .font(TypeScale.caption)
                        .foregroundStyle(Palette.inkFaint)
                }
                Spacer(minLength: Space.snug)
                Capsule()
                    .fill(isOn ? Palette.ink : Palette.lineStrong)
                    .frame(width: 42, height: 26)
                    .overlay(alignment: isOn ? .trailing : .leading) {
                        Circle()
                            .fill(Palette.canvas)
                            .frame(width: 20, height: 20)
                            .padding(3)
                    }
                    .animation(Motion.soft, value: isOn)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableStyle(scale: 0.995))
    }
}
