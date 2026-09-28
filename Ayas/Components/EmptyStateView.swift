import SwiftUI

/// What someone sees before they have anything. It has one job: make the first habit feel
/// small enough to say yes to.
struct EmptyStateView: View {
    var onQuickStart: () -> Void
    var onCustom: () -> Void

    @State private var seeded = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: Space.generous)

            SeedMark()
                .frame(width: 54, height: 54)
                .scaleEffect(seeded ? 1 : 0.7)
                .opacity(seeded ? 1 : 0)

            Text("Start ridiculously small.")
                .font(.system(size: 29, weight: .regular, design: .serif))
                .foregroundStyle(Palette.ink)
                .multilineTextAlignment(.center)
                .padding(.top, Space.roomy)

            Text("One ayah. One page. Ten pushups.\nSomething you could still do on your worst day.")
                .font(TypeScale.body)
                .foregroundStyle(Palette.inkSoft)
                .multilineTextAlignment(.center)
                .lineSpacing(5)
                .padding(.top, Space.snug)
                .frame(maxWidth: 300)

            Spacer(minLength: Space.generous)

            VStack(spacing: Space.snug) {
                Button("Read one ayah a day", action: onQuickStart)
                    .buttonStyle(FilledButtonStyle())

                Button("Something else", action: onCustom)
                    .buttonStyle(OutlineButtonStyle())
            }
            .opacity(seeded ? 1 : 0)
            .offset(y: seeded ? 0 : 10)

            Spacer(minLength: Space.regular)
        }
        .onAppear {
            withAnimation(Motion.settle.delay(0.1)) { seeded = true }
        }
    }
}

/// A seed: one ring, one dot. The app's quietest possible statement of itself.
private struct SeedMark: View {
    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(Palette.lineStrong, lineWidth: 1)
            Circle()
                .fill(AccentKey.olive.color)
                .frame(width: 9, height: 9)
        }
    }
}
