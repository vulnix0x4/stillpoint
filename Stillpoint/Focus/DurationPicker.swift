import SwiftUI

/// The orb inside its dial, with the chosen length written on the orb's bright core.
struct DurationPicker: View {
    @Binding var minutes: Int
    @Binding var isFlow: Bool
    var palette: OrbPalette

    var body: some View {
        ZStack {
            LivingOrb(palette: palette, turbulence: 0.5)
                .padding(26)

            DurationDial(minutes: $minutes, isFlow: isFlow, palette: palette)

            VStack(spacing: 0) {
                if isFlow {
                    Image(systemName: "infinity")
                        .font(.system(.largeTitle, design: .rounded))
                        .bold()
                } else {
                    Text(minutes, format: .number)
                        .font(.system(.largeTitle, design: .rounded))
                        .bold()
                        .monospacedDigit()
                        .contentTransition(.numericText(value: Double(minutes)))
                }
                Text(isFlow ? "open flow" : "minutes")
                    .font(.subheadline)
                    .textCase(.uppercase)
                    .kerning(1.5)
            }
            .foregroundStyle(Theme.ink)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .animation(Theme.Motion.quick, value: minutes)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}
