import SwiftUI

/// An orb that animates on its own. Slows to a near stand-still with Reduce Motion.
struct LivingOrb: View {
    var palette: OrbPalette
    var turbulence = 0.45
    var energy = 0.0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var origin = Date.now

    var body: some View {
        TimelineView(.animation(minimumInterval: reduceMotion ? 0.25 : 1 / 30)) { context in
            OrbRenderer(
                palette: palette,
                time: context.date.timeIntervalSince(origin) * (reduceMotion ? 0.12 : 1),
                turbulence: turbulence,
                energy: energy
            )
        }
    }
}

#Preview {
    LivingOrb(palette: .ember)
        .frame(width: 320, height: 320)
        .background(Theme.canvas)
}
