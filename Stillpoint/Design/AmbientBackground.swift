import SwiftUI

/// A dark, slowly drifting wash of the palette's colours with fine grain on top.
struct AmbientBackground: View {
    var palette: OrbPalette
    /// 0...1. How much colour bleeds into the canvas.
    var intensity = 1.0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 12, paused: reduceMotion)) { context in
            MeshGradient(
                width: 3,
                height: 3,
                points: Self.points(at: context.date.timeIntervalSinceReferenceDate),
                colors: colors
            )
        }
        .colorEffect(ShaderLibrary.grain(.float(0.03)))
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    private var colors: [Color] {
        let rim = Theme.canvas.mix(with: palette.rim, by: 0.30 * intensity)
        let mid = Theme.canvas.mix(with: palette.mid, by: 0.14 * intensity)
        let faint = Theme.canvas.mix(with: palette.rim, by: 0.12 * intensity)
        return [
            rim, Theme.canvas, faint,
            Theme.canvas, mid, Theme.canvas,
            faint, Theme.canvas, rim,
        ]
    }

    /// Interior points orbit gently; edge points stay pinned so the mesh always fills the view.
    private static func points(at time: Double) -> [SIMD2<Float>] {
        let t = time * 0.08
        let wobble = { (phase: Double, amount: Double) in Float(sin(t + phase) * amount) }
        return [
            [0, 0], [0.5 + wobble(0, 0.12), 0], [1, 0],
            [0, 0.5 + wobble(1.3, 0.1)], [0.5 + wobble(2.1, 0.14), 0.5 + wobble(0.7, 0.12)], [1, 0.5 + wobble(2.9, 0.1)],
            [0, 1], [0.5 + wobble(3.7, 0.12), 1], [1, 1],
        ]
    }
}

#Preview {
    AmbientBackground(palette: .tide)
}
