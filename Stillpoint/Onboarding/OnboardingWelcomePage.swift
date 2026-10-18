import SwiftUI

struct OnboardingWelcomePage: View {
    var palette: OrbPalette
    var next: () -> Void

    @ScaledMetric(relativeTo: .largeTitle) private var titleSize = 44.0

    var body: some View {
        VStack(spacing: Theme.Spacing.large) {
            Spacer(minLength: 0)
            LivingOrb(palette: palette, turbulence: 0.35, energy: 0.2)
                .frame(maxWidth: 300)
                .aspectRatio(1, contentMode: .fit)
            VStack(spacing: Theme.Spacing.small) {
                Text("Stillpoint")
                    .font(.system(size: titleSize, design: .serif))
                Text("Attention is where your life actually happens. Give it somewhere quiet to land.")
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            OnboardingButton(title: "Continue", action: next)
        }
        .padding(.horizontal, Theme.Spacing.xLarge)
        .padding(.bottom, Theme.Spacing.xLarge * 1.5)
    }
}
