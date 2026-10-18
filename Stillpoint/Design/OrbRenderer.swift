import SwiftUI

/// Draws the orb shader for one moment in time. Purely a function of its inputs.
struct OrbRenderer: View {
    var palette: OrbPalette
    var time: Double
    var turbulence: Double
    var energy: Double

    var body: some View {
        Rectangle()
            .fill(
                ShaderLibrary.orb(
                    .boundingRect,
                    .float(time),
                    .float(turbulence),
                    .float(energy),
                    .color(palette.core),
                    .color(palette.mid),
                    .color(palette.rim)
                )
            )
            .accessibilityHidden(true)
    }
}
