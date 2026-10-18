import SwiftUI

/// A fine luminous ring around the orb showing progress toward the goal.
struct ProgressRing: View {
    var progress: Double
    var palette: OrbPalette
    var isOpenEnded: Bool
    var isComplete: Bool

    private static let lineWidth: Double = 4

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.07), lineWidth: Self.lineWidth)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(colors: [palette.rim, palette.mid, palette.core], center: .center, startAngle: .zero, endAngle: .degrees(360 * max(progress, 0.01))),
                    style: StrokeStyle(lineWidth: Self.lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .opacity(isOpenEnded ? 0.45 : 1)
                .shadow(color: palette.mid.opacity(isComplete ? 0.95 : 0.5), radius: isComplete ? 14 : 6)
        }
        .padding(Self.lineWidth / 2)
        .accessibilityHidden(true)
    }
}
