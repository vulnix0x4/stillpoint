import SwiftUI

/// A single ring that spreads out from the orb whenever `trigger` changes, like a stone
/// dropped in still water. Used when a thought is parked.
struct RippleRing: View {
    var trigger: Int
    var color: Color

    private struct Ripple {
        var scale = 1.0
        var opacity = 0.0
    }

    var body: some View {
        Circle()
            .stroke(color, lineWidth: 2)
            .keyframeAnimator(initialValue: Ripple(), trigger: trigger) { content, ripple in
                content
                    .scaleEffect(ripple.scale)
                    .opacity(ripple.opacity)
            } keyframes: { _ in
                KeyframeTrack(\.scale) {
                    LinearKeyframe(1.0, duration: 0.01)
                    CubicKeyframe(1.45, duration: 1.6)
                }
                KeyframeTrack(\.opacity) {
                    LinearKeyframe(0.8, duration: 0.08)
                    CubicKeyframe(0, duration: 1.5)
                }
            }
            .accessibilityHidden(true)
    }
}
