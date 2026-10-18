import SwiftUI

struct WidgetBackground: View {
    var palette: OrbPalette

    private static let canvas = Color(red: 0.035, green: 0.039, blue: 0.063)

    var body: some View {
        ZStack {
            Self.canvas
            RadialGradient(
                colors: [palette.rim.opacity(0.55), .clear],
                center: .topLeading,
                startRadius: 0,
                endRadius: 220
            )
            RadialGradient(
                colors: [palette.mid.opacity(0.18), .clear],
                center: .bottomTrailing,
                startRadius: 0,
                endRadius: 200
            )
        }
    }
}
