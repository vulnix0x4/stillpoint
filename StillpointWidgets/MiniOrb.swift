import SwiftUI

/// A static rendition of the orb for places shaders can't go.
struct MiniOrb: View {
    var palette: OrbPalette
    var glow = true

    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [palette.core, palette.mid, palette.rim],
                    center: UnitPoint(x: 0.42, y: 0.36),
                    startRadius: 0,
                    endRadius: 40
                )
            )
            .shadow(color: glow ? palette.mid.opacity(0.7) : .clear, radius: 6)
            .accessibilityHidden(true)
    }
}
