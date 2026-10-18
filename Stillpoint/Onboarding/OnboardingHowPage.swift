import SwiftUI

struct OnboardingHowPage: View {
    var next: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.large) {
            Spacer(minLength: 0)
            Text("One thing at a time")
                .font(.display)
            VStack(alignment: .leading, spacing: Theme.Spacing.large) {
                OnboardingStep(symbol: "scope", title: "Name it", detail: "Every session starts with a single intention. Small and concrete works best.")
                OnboardingStep(symbol: "wind", title: "Arrive", detail: "A minute of breathing and a soundscape synthesised on the spot help you settle.")
                OnboardingStep(symbol: "tray.and.arrow.down", title: "Park it", detail: "When a stray thought pulls, write it down and let it go. It waits for you afterwards.")
                OnboardingStep(symbol: "circle.hexagongrid", title: "Go deep", detail: "The orb calms as your focus settles. Past a quarter of an hour, you're in deep water.")
                OnboardingStep(symbol: "chart.bar.xaxis", title: "Learn", detail: "Short reflections reveal when, and how, you focus best.")
            }
            Spacer(minLength: 0)
            OnboardingButton(title: "Continue", action: next)
        }
        .padding(.horizontal, Theme.Spacing.xLarge)
        .padding(.bottom, Theme.Spacing.xLarge * 1.5)
    }
}
