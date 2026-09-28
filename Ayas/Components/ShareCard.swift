import SwiftUI

/// The image that goes out when someone shares a habit.
///
/// Square, because that is what survives every feed and message thread intact. It shows the
/// run and the shape of the last two weeks — enough to be worth posting, never a scoreboard.
struct ShareCard: View {
    var snapshot: HabitSnapshot
    var marks: [DayMark]
    var today: DayKey

    static let side: CGFloat = 340

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 7) {
                Image(systemName: snapshot.glyph.symbolName)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(snapshot.accent.color)
                Text(snapshot.name)
                    .font(.system(size: 20, weight: .regular, design: .serif))
                    .foregroundStyle(Palette.ink)
                Spacer(minLength: 0)
                if snapshot.isComplete {
                    CompletionMark(isComplete: true, accent: snapshot.accent, size: 22)
                }
            }

            Text(snapshot.action)
                .font(.system(size: 13))
                .foregroundStyle(Palette.inkSoft)
                .padding(.top, 4)

            Spacer(minLength: 16)

            HStack(alignment: .lastTextBaseline, spacing: 7) {
                Text("\(snapshot.streak)")
                    .font(.system(size: 76, weight: .regular, design: .serif))
                    .foregroundStyle(Palette.ink)
                Text(snapshot.streak == 1 ? "day" : "days")
                    .font(.system(size: 19, weight: .regular, design: .serif))
                    .foregroundStyle(Palette.inkSoft)
                    .padding(.bottom, 9)
            }

            Text("in a row")
                .eyebrow(size: 10, color: snapshot.accent.color)
                .padding(.top, 2)

            Spacer(minLength: 16)

            HStack(alignment: .bottom, spacing: 5) {
                ForEach(marks) { mark in
                    Capsule(style: .continuous)
                        .fill(mark.done ? snapshot.accent.color : Palette.line)
                        .frame(width: 5, height: mark.day == today ? 26 : 19)
                }
            }

            Spacer(minLength: 14)

            HStack(alignment: .center) {
                if let reference = snapshot.item?.reference {
                    Text(reference)
                        .eyebrow(size: 9, color: Palette.inkFaint)
                        .lineLimit(1)
                }
                Spacer(minLength: 8)
                HStack(spacing: 5) {
                    SeedGlyph()
                        .frame(width: 11, height: 11)
                    Text("Ayas")
                        .font(.system(size: 12, weight: .regular, design: .serif))
                        .foregroundStyle(Palette.inkFaint)
                }
            }
        }
        .padding(26)
        .frame(width: Self.side, height: Self.side, alignment: .topLeading)
        .background(
            LinearGradient(
                colors: [snapshot.accent.wash, Palette.canvas],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

/// The app's mark, small enough to sign a card with.
private struct SeedGlyph: View {
    var body: some View {
        ZStack {
            Circle().strokeBorder(Palette.inkFaint, lineWidth: 1)
            Circle().fill(AccentKey.olive.color).scaleEffect(0.32)
        }
    }
}

enum ShareCardRenderer {
    /// Rendered in light mode regardless of the app's appearance, so a shared card looks the
    /// same to everyone who receives it.
    @MainActor
    static func image(for habit: Habit, on day: DayKey) -> Image? {
        let card = ShareCard(
            snapshot: HabitSnapshot(habit: habit, day: day, includeTranslation: false),
            marks: habit.recentDays(endingOn: day, count: 14),
            today: day
        )
        .environment(\.colorScheme, .light)

        let renderer = ImageRenderer(content: card)
        renderer.scale = 3
        guard let rendered = renderer.uiImage else { return nil }
        return Image(uiImage: rendered)
    }

    /// The words that travel with the image.
    static func message(for habit: Habit, on day: DayKey) -> String {
        let streak = habit.currentStreak(asOf: day)
        let run: String
        switch streak {
        case 0: run = "Starting again"
        case 1: run = "Day one"
        default: run = "\(streak) days in a row"
        }
        return "\(run) — \(habit.action.lowercased()), every day. #Ayas"
    }
}
