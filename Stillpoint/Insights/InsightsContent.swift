import SwiftUI

/// The scrolling body of the Insights tab.
struct InsightsContent: View {
    var sessions: [FocusSession]
    var palette: OrbPalette

    @AppStorage(PreferenceKey.dailyGoalMinutes) private var dailyGoal = PreferenceKey.Default.dailyGoalMinutes

    var body: some View {
        let now = Date.now
        let records = sessions.map(\.record)
        let stats = StatsCalculator()
        let insights = InsightGenerator().insights(for: records, now: now)

        ScrollView {
            LazyVStack(alignment: .leading, spacing: Theme.Spacing.large) {
                SummaryGrid(
                    today: stats.focusedSeconds(records, on: now),
                    streak: stats.currentStreak(records, now: now),
                    longestStreak: stats.longestStreak(records),
                    week: stats.weekTotal(records, containing: now),
                    averageDepth: stats.averageDepth(records)
                )

                DailyFocusChart(records: records, goalMinutes: dailyGoal, palette: palette)
                    .cardSurface()

                if !insights.isEmpty {
                    VStack(alignment: .leading, spacing: Theme.Spacing.small) {
                        SectionTitle("What the data says")
                        ForEach(insights) { insight in
                            InsightCard(insight: insight)
                        }
                    }
                }

                FocusHeatmap(cells: stats.heatmap(records, weeks: 18, now: now), palette: palette)
                    .cardSurface()

                PeakHoursChart(hours: stats.hourlyTotals(records), palette: palette)
                    .cardSurface()

                VStack(alignment: .leading, spacing: Theme.Spacing.small) {
                    SectionTitle("Recent sessions")
                    VStack(spacing: 0) {
                        ForEach(sessions.prefix(25)) { session in
                            NavigationLink(value: session) {
                                SessionHistoryRow(session: session)
                            }
                            .buttonStyle(.plain)
                            if session.id != sessions.prefix(25).last?.id {
                                Divider().overlay(Theme.hairline)
                            }
                        }
                    }
                    .cardSurface()
                }
            }
            .padding(.horizontal, Theme.Spacing.medium)
            .padding(.bottom, Theme.Spacing.xLarge)
        }
        .scrollIndicators(.hidden)
    }
}
