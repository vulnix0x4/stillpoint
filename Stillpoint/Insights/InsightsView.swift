import SwiftData
import SwiftUI

/// Patterns over time: totals, streaks, when you focus best, and what helps.
struct InsightsView: View {
    @Query(filter: #Predicate<FocusSession> { $0.isFinalized }, sort: \FocusSession.startDate, order: .reverse)
    private var sessions: [FocusSession]
    @AppStorage(PreferenceKey.palette) private var paletteName = OrbPalette.ember.rawValue

    var body: some View {
        let palette = OrbPalette.named(paletteName)

        NavigationStack {
            Group {
                if sessions.isEmpty {
                    ContentUnavailableView {
                        Label("No sessions yet", systemImage: "chart.bar.xaxis")
                    } description: {
                        Text("Finish a focus session and your patterns will start to appear here.")
                    }
                } else {
                    InsightsContent(sessions: sessions, palette: palette)
                }
            }
            .background {
                AmbientBackground(palette: palette, intensity: 0.6)
            }
            .navigationTitle("Insights")
            .navigationDestination(for: FocusSession.self) { session in
                SessionDetailView(session: session, palette: palette)
            }
        }
    }
}
