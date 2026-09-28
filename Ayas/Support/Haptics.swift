import UIKit

/// Physical feedback for the one gesture that matters. Soft rather than sharp — this is a
/// calm app, not a game.
enum Haptics {
    static func completed(enabled: Bool) {
        guard enabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.prepare()
        generator.impactOccurred(intensity: 0.9)
    }

    static func undone(enabled: Bool) {
        guard enabled else { return }
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 0.4)
    }

    static func selection(enabled: Bool) {
        guard enabled else { return }
        UISelectionFeedbackGenerator().selectionChanged()
    }
}
