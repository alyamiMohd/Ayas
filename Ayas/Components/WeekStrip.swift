import SwiftUI

/// History as stitches rather than a chart: one mark per day, filled when it was done.
///
/// Deliberately not a graph. It answers "have I been showing up?" at a glance and then gets
/// out of the way.
struct WeekStrip: View {
    var marks: [DayMark]
    var accent: AccentKey
    var today: DayKey

    var body: some View {
        VStack(alignment: .leading, spacing: Space.snug) {
            HStack(alignment: .bottom, spacing: 5) {
                ForEach(marks) { mark in
                    Capsule(style: .continuous)
                        .fill(mark.done ? accent.color : Palette.line)
                        .frame(width: 4, height: mark.day == today ? 22 : 16)
                        .overlay(alignment: .bottom) {
                            if mark.day == today {
                                Circle()
                                    .fill(mark.done ? accent.color : Palette.lineStrong)
                                    .frame(width: 3, height: 3)
                                    .offset(y: 7)
                            }
                        }
                }
            }
            .animation(Motion.soft, value: marks)

            if let first = marks.first?.day {
                Text("Since \(DateText.shortDay(first)) · today at the end")
                    .font(TypeScale.caption)
                    .foregroundStyle(Palette.inkFaint)
            }
        }
    }
}

/// Small date helpers. One formatter cache, so nothing is rebuilt per row.
enum DateText {
    private static let dayMonth: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("d MMM")
        return formatter
    }()

    private static let weekdayFull: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("EEEE d MMMM")
        return formatter
    }()

    static func shortDay(_ day: DayKey) -> String {
        dayMonth.string(from: day.noon())
    }

    static func longDay(_ day: DayKey) -> String {
        weekdayFull.string(from: day.noon())
    }
}
