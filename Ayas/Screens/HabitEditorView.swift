import SwiftUI

/// Create or edit a habit. Four decisions at most, and only one of them is required thought:
/// what is the smallest version of this thing?
struct HabitEditorView: View {
    enum Mode {
        case create(HabitTemplate?)
        case edit(Habit)
    }

    var mode: Mode
    var onSave: (Habit) -> Void
    var onDelete: (() -> Void)?

    @Environment(HabitStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var action: String
    @State private var glyph: Glyph
    @State private var accent: AccentKey
    @State private var contentKind: ContentKind
    @State private var surahNumber: Int
    @State private var ayahNumber: Int
    @State private var unit: String
    @State private var startNumber: Int
    @State private var showsStartPicker = false
    @State private var confirmingDelete = false

    private enum ContentKind: String, CaseIterable, Identifiable {
        case plain, quran, counting

        var id: String { rawValue }

        var label: String {
            switch self {
            case .plain: return "Nothing"
            case .quran: return "Quran"
            case .counting: return "Counting"
            }
        }

        var explanation: String {
            switch self {
            case .plain: return "The same action every day."
            case .quran: return "One ayah a day, continuing from where you left off."
            case .counting: return "Counts up one step each day — page 1, page 2, and on."
            }
        }
    }

    init(mode: Mode, onSave: @escaping (Habit) -> Void, onDelete: (() -> Void)? = nil) {
        self.mode = mode
        self.onSave = onSave
        self.onDelete = onDelete

        let seed: (name: String, action: String, glyph: Glyph, accent: AccentKey, sequence: HabitSequence)
        switch mode {
        case .create(let template):
            if let template {
                seed = (template.name, template.action, template.glyph, template.accent, template.sequence)
            } else {
                seed = ("", "", .leaf, .ember, .none)
            }
        case .edit(let habit):
            seed = (habit.name, habit.action, habit.glyph, habit.accent, habit.sequence)
        }

        _name = State(initialValue: seed.name)
        _action = State(initialValue: seed.action)
        _glyph = State(initialValue: seed.glyph)
        _accent = State(initialValue: seed.accent)

        switch seed.sequence {
        case .none:
            _contentKind = State(initialValue: .plain)
            _surahNumber = State(initialValue: 1)
            _ayahNumber = State(initialValue: 1)
            _unit = State(initialValue: "Page")
            _startNumber = State(initialValue: 1)
        case .quran(let start):
            let location = QuranLibrary.shared.location(ofAyah: start)
            _contentKind = State(initialValue: .quran)
            _surahNumber = State(initialValue: location?.surah.number ?? 1)
            _ayahNumber = State(initialValue: location?.ayah ?? 1)
            _unit = State(initialValue: "Page")
            _startNumber = State(initialValue: 1)
        case .numbered(let unit, let start):
            _contentKind = State(initialValue: .counting)
            _surahNumber = State(initialValue: 1)
            _ayahNumber = State(initialValue: 1)
            _unit = State(initialValue: unit)
            _startNumber = State(initialValue: start)
        }
    }

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !action.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ZStack {
            CanvasBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: Space.roomy) {
                    header

                    UnderlinedField(label: "Habit", placeholder: "Quran", text: $name, accent: accent)
                    UnderlinedField(label: "Tiny action", placeholder: "Read one ayah", text: $action, accent: accent)

                    appearanceSection
                    contentSection
                    rhythmSection

                    if isEditing, onDelete != nil {
                        deleteSection
                    }

                    Spacer(minLength: Space.regular)
                }
                .padding(.horizontal, Space.gutter)
                .padding(.top, Space.regular)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
        }
        .presentationDragIndicator(.hidden)
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Button("Cancel") { dismiss() }
                .font(TypeScale.body)
                .foregroundStyle(Palette.inkFaint)

            Spacer()

            Button(isEditing ? "Save" : "Create") { save() }
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(canSave ? accent.color : Palette.inkFaint)
                .disabled(!canSave)
        }
        .padding(.bottom, Space.tight)
    }

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: Space.regular) {
            SectionLabel(text: "Colour")
            HStack(spacing: Space.regular) {
                ForEach(AccentKey.allCases, id: \.self) { option in
                    Button {
                        Haptics.selection(enabled: store.settings.haptics)
                        withAnimation(Motion.soft) { accent = option }
                    } label: {
                        Circle()
                            .fill(option.color)
                            .frame(width: 24, height: 24)
                            .overlay(
                                Circle()
                                    .strokeBorder(Palette.canvas, lineWidth: 2)
                                    .padding(-4)
                                    .opacity(accent == option ? 1 : 0)
                            )
                            .overlay(
                                Circle()
                                    .strokeBorder(option.color, lineWidth: 1)
                                    .padding(-5)
                                    .opacity(accent == option ? 1 : 0)
                            )
                    }
                    .buttonStyle(PressableStyle(scale: 0.86))
                    .accessibilityLabel(option.label)
                }
                Spacer(minLength: 0)
            }

            SectionLabel(text: "Mark")
                .padding(.top, Space.tight)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: Space.regular) {
                ForEach(Glyph.allCases, id: \.self) { option in
                    Button {
                        Haptics.selection(enabled: store.settings.haptics)
                        withAnimation(Motion.soft) { glyph = option }
                    } label: {
                        Image(systemName: option.symbolName)
                            .font(.system(size: 16, weight: .regular))
                            .foregroundStyle(glyph == option ? accent.color : Palette.inkFaint)
                            .frame(width: 40, height: 40)
                            .background(
                                Circle()
                                    .fill(glyph == option ? accent.wash : Color.clear)
                            )
                    }
                    .buttonStyle(PressableStyle(scale: 0.9))
                }
            }
        }
    }

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: Space.snug) {
            SectionLabel(text: "Daily content")

            SegmentedRow(
                options: ContentKind.allCases,
                selection: $contentKind,
                accent: accent,
                label: \.label
            )

            Text(contentKind.explanation)
                .font(TypeScale.caption)
                .foregroundStyle(Palette.inkFaint)
                .padding(.top, 2)

            switch contentKind {
            case .plain:
                EmptyView()
            case .quran:
                quranStart
            case .counting:
                countingStart
            }
        }
        .animation(Motion.soft, value: contentKind)
    }

    @ViewBuilder
    private var quranStart: some View {
        if QuranLibrary.shared.isAvailable {
            VStack(alignment: .leading, spacing: Space.snug) {
                Button {
                    withAnimation(Motion.soft) { showsStartPicker.toggle() }
                } label: {
                    HStack {
                        Text("Starts at")
                            .font(TypeScale.bodySmall)
                            .foregroundStyle(Palette.inkSoft)
                        Spacer()
                        Text(startLabel)
                            .eyebrow(size: 10, color: accent.color)
                        Image(systemName: showsStartPicker ? "chevron.up" : "chevron.down")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Palette.inkFaint)
                    }
                    .padding(.vertical, Space.snug)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PressableStyle(scale: 0.995))

                if showsStartPicker {
                    HStack(spacing: 0) {
                        Picker("Surah", selection: $surahNumber) {
                            ForEach(QuranLibrary.shared.surahs) { surah in
                                Text("\(surah.number). \(surah.latinName)").tag(surah.number)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(maxWidth: .infinity)

                        Picker("Ayah", selection: $ayahNumber) {
                            ForEach(1...maxAyah, id: \.self) { number in
                                Text("\(number)").tag(number)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 90)
                    }
                    .frame(height: 140)
                    .tint(accent.color)
                    .onChange(of: surahNumber) { _, _ in
                        ayahNumber = min(ayahNumber, maxAyah)
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                Hairline()
            }
        } else {
            Text("The Quran text could not be found in this build.")
                .font(TypeScale.caption)
                .foregroundStyle(Palette.inkFaint)
        }
    }

    private var countingStart: some View {
        HStack(spacing: Space.regular) {
            VStack(alignment: .leading, spacing: Space.tight) {
                Text("Unit").eyebrow()
                TextField("Page", text: $unit)
                    .font(TypeScale.body)
                    .foregroundStyle(Palette.ink)
                    .tint(accent.color)
                Hairline()
            }

            VStack(alignment: .leading, spacing: Space.tight) {
                Text("Starts at").eyebrow()
                TextField("1", value: $startNumber, format: .number)
                    .font(TypeScale.body)
                    .foregroundStyle(Palette.ink)
                    .tint(accent.color)
                    .keyboardType(.numberPad)
                Hairline()
            }
            .frame(width: 90)
        }
        .padding(.top, Space.tight)
    }

    private var rhythmSection: some View {
        VStack(alignment: .leading, spacing: Space.tight) {
            SectionLabel(text: "Rhythm")
            Text("Every day")
                .font(TypeScale.body)
                .foregroundStyle(Palette.ink)
            Text("Daily only, for now. Small things work best when they are not up for negotiation.")
                .font(TypeScale.caption)
                .foregroundStyle(Palette.inkFaint)
        }
    }

    private var deleteSection: some View {
        VStack(alignment: .leading, spacing: Space.snug) {
            Hairline()
            if confirmingDelete {
                VStack(alignment: .leading, spacing: Space.snug) {
                    Text("Delete this habit and its history?")
                        .font(TypeScale.bodySmall)
                        .foregroundStyle(Palette.ink)
                    HStack(spacing: Space.regular) {
                        Button("Delete") {
                            onDelete?()
                            dismiss()
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AccentKey.rose.color)

                        Button("Keep it") {
                            withAnimation(Motion.soft) { confirmingDelete = false }
                        }
                        .font(TypeScale.bodySmall)
                        .foregroundStyle(Palette.inkFaint)
                    }
                }
                .padding(.top, Space.tight)
            } else {
                Button("Delete habit") {
                    withAnimation(Motion.soft) { confirmingDelete = true }
                }
                .font(TypeScale.bodySmall)
                .foregroundStyle(Palette.inkFaint)
                .padding(.top, Space.tight)
            }
        }
    }

    // MARK: - Helpers

    private var maxAyah: Int {
        QuranLibrary.shared.surah(numbered: surahNumber)?.ayahCount ?? 1
    }

    private var startLabel: String {
        guard let surah = QuranLibrary.shared.surah(numbered: surahNumber) else { return "—" }
        return "\(surah.latinName) · \(ayahNumber)"
    }

    private var composedSequence: HabitSequence {
        switch contentKind {
        case .plain:
            return .none
        case .quran:
            let index = QuranLibrary.shared.globalIndex(surah: surahNumber, ayah: ayahNumber) ?? 1
            return .quran(start: index)
        case .counting:
            let trimmed = unit.trimmingCharacters(in: .whitespacesAndNewlines)
            return .numbered(unit: trimmed.isEmpty ? "Step" : trimmed, start: max(startNumber, 0))
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAction = action.trimmingCharacters(in: .whitespacesAndNewlines)

        switch mode {
        case .create:
            let habit = Habit(
                name: trimmedName,
                action: trimmedAction,
                glyph: glyph,
                accent: accent,
                sequence: composedSequence,
                createdOn: store.today()
            )
            onSave(habit)
        case .edit(let existing):
            var updated = existing
            updated.name = trimmedName
            updated.action = trimmedAction
            updated.glyph = glyph
            updated.accent = accent
            updated.sequence = composedSequence
            onSave(updated)
        }
        dismiss()
    }
}

/// A flat, hairline segmented control. Does the job of a system picker without borrowing its
/// look.
private struct SegmentedRow<Option: Identifiable & Equatable>: View {
    var options: [Option]
    @Binding var selection: Option
    var accent: AccentKey
    var label: (Option) -> String

    var body: some View {
        HStack(spacing: Space.tight) {
            ForEach(options) { option in
                let isSelected = option == selection
                Button {
                    withAnimation(Motion.soft) { selection = option }
                } label: {
                    Text(label(option))
                        .font(.system(size: 13, weight: isSelected ? .medium : .regular))
                        .foregroundStyle(isSelected ? Palette.onAccent : Palette.inkSoft)
                        .padding(.vertical, 9)
                        .frame(maxWidth: .infinity)
                        .background(
                            Capsule()
                                .fill(isSelected ? accent.color : Palette.canvasLow)
                        )
                }
                .buttonStyle(PressableStyle(scale: 0.97))
            }
        }
    }
}
