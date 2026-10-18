import SwiftData
import SwiftUI

struct RootView: View {
    @Environment(SessionEngine.self) private var engine
    @AppStorage(PreferenceKey.palette) private var paletteName = OrbPalette.ember.rawValue
    @AppStorage(PreferenceKey.hasOnboarded) private var hasOnboarded = false
    @Query(filter: #Predicate<ParkedThought> { !$0.isDone }) private var openThoughts: [ParkedThought]
    @State private var selectedTab = AppTab.focus

    var body: some View {
        @Bindable var engine = engine
        let palette = OrbPalette.named(paletteName)

        TabView(selection: $selectedTab) {
            Tab("Focus", systemImage: "circle.circle", value: .focus) {
                FocusHomeView()
            }
            Tab("Insights", systemImage: "chart.bar.xaxis", value: .insights) {
                InsightsView()
            }
            Tab("Parked", systemImage: "tray", value: .parked) {
                ThoughtsView()
            }
            .badge(openThoughts.count)
        }
        .tint(palette.accent)
        .fullScreenCover(isPresented: $engine.isSessionPresented) {
            SessionContainerView()
        }
        .overlay {
            if !hasOnboarded {
                OnboardingView()
                    .transition(.opacity)
            }
        }
        .animation(Theme.Motion.settle, value: hasOnboarded)
    }
}
