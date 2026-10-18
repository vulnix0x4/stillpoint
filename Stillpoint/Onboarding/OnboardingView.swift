import SwiftUI

/// Three quiet pages: why, how, and a first goal.
struct OnboardingView: View {
    @AppStorage(PreferenceKey.hasOnboarded) private var hasOnboarded = false
    @AppStorage(PreferenceKey.palette) private var paletteName = OrbPalette.ember.rawValue
    @AppStorage(PreferenceKey.dailyGoalMinutes) private var dailyGoal = PreferenceKey.Default.dailyGoalMinutes
    @State private var page = 0

    var body: some View {
        let palette = OrbPalette.named(paletteName)

        ZStack {
            AmbientBackground(palette: palette)

            TabView(selection: $page) {
                OnboardingWelcomePage(palette: palette, next: advance)
                    .tag(0)
                OnboardingHowPage(next: advance)
                    .tag(1)
                OnboardingGoalPage(goal: $dailyGoal, paletteName: $paletteName, finish: finish)
                    .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .interactive))
        }
        .tint(palette.accent)
        .preferredColorScheme(.dark)
    }

    private func advance() {
        withAnimation(Theme.Motion.settle) {
            page = min(page + 1, 2)
        }
    }

    private func finish() {
        Task {
            await NotificationScheduler().requestAuthorization()
            hasOnboarded = true
        }
    }
}
