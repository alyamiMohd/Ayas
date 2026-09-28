import SwiftUI

/// Motion is the reward in this app, so it is tuned rather than decorative: one confident
/// spring for completion, and softer curves for everything else.
enum Motion {
    /// The completion gesture. Enough overshoot to feel like a stamp, not a bounce.
    static let complete = Animation.spring(response: 0.38, dampingFraction: 0.68)
    /// Undoing a completion — quicker and flatter, deliberately less rewarding.
    static let undo = Animation.spring(response: 0.3, dampingFraction: 0.9)
    /// State cross-fades and layout settles.
    static let soft = Animation.easeInOut(duration: 0.26)
    /// Rows appearing, sheets resolving.
    static let settle = Animation.spring(response: 0.5, dampingFraction: 0.86)
}

/// Shared geometry so every corner in the app belongs to the same family.
enum Radius {
    static let medium: CGFloat = 18
    static let large: CGFloat = 26
}

enum Space {
    static let tight: CGFloat = 6
    static let snug: CGFloat = 12
    static let regular: CGFloat = 18
    static let roomy: CGFloat = 28
    static let generous: CGFloat = 44
    /// Page gutter. Wide on purpose: the breathing room is the design.
    static let gutter: CGFloat = 26
}
