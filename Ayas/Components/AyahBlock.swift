import SwiftUI

/// Today's content, given room to breathe.
///
/// This is the one place in the app that gets a filled surface, because it is the one place
/// the reader is meant to stop and stay for a moment.
struct AyahBlock: View {
    var item: SequenceItem
    var accent: AccentKey
    var isComplete: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Space.regular) {
            HStack(alignment: .center, spacing: Space.snug) {
                Text(item.reference)
                    .eyebrow(size: 10, color: accent.color)
                Spacer(minLength: Space.tight)
                // Completion takes over the slot the progress count sits in, so finishing
                // visibly resolves the block rather than adding another thing to it.
                if isComplete {
                    CompletionMark(isComplete: true, accent: accent, size: 22)
                        .transition(.scale.combined(with: .opacity))
                } else if let progress = item.progress {
                    Text(progress)
                        .font(TypeScale.caption)
                        .foregroundStyle(Palette.inkFaint)
                        .transition(.opacity)
                }
            }

            if let body = item.body {
                ArabicText(text: body, size: 25, lineLimit: nil)
                    .padding(.vertical, Space.tight)
            } else {
                Text(item.reference.capitalized)
                    .font(TypeScale.sectionTitle)
                    .foregroundStyle(Palette.ink)
            }

            if let translation = item.translation {
                Text(translation)
                    .font(.system(size: 15, weight: .regular, design: .serif))
                    .italic()
                    .foregroundStyle(Palette.inkSoft)
                    .lineSpacing(5)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(Space.roomy)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: Radius.large, style: .continuous)
                .fill(accent.wash)
        )
        .animation(Motion.complete, value: isComplete)
    }
}
