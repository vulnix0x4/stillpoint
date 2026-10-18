import SwiftUI

/// Today's progress around a small orb.
struct GoalRing: View {
    var progress: Double
    var palette: OrbPalette
    var lineWidth: Double = 7

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(progress, 0.001))
                .stroke(
                    AngularGradient(colors: [palette.rim, palette.mid, palette.core], center: .center),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            MiniOrb(palette: palette)
                .padding(lineWidth * 2.4)
        }
        .padding(lineWidth / 2)
    }
}
