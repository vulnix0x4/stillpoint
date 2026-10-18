import Combine
import SwiftUI

/// The scrolling body of the Insights tab.
struct InsightsContent: View {
    var sessions: [FocusSession]
    var palette: OrbPalette

    @AppStorage(PreferenceKey.dailyGoalMinutes) private var dailyGoal = PreferenceKey.Default.dailyGoalMinutes
    @State private var today = Date.now
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        let now = today
        let records = sessions.map(\.record)
        let stats = StatsCalculator()
        let insights = InsightGenerator().insights(for: records, now: now)
        let firstDay = records.map(\.start).min().map(Calendar.current.startOfDay)
        // Show as many weeks as there is history for, within a readable range.
        let historyWeeks = firstDay.map { Int(now.timeIntervalSince($0) / 604_800) + 2 } ?? 8
        let heatmapWeeks = min(18, max(8, historyWeeks))

        ScrollView {
            LazyVStack(alignment: .leading, spacing: Theme.Spacing.large) {
                SummaryGrid(
                    today: stats.focusedSeconds(records, on: now),
                    streak: stats.currentStreak(records, now: now),
                    longestStreak: stats.longestStreak(records),
                    week: stats.dailyTotals(records, days: 7, endingOn: now).reduce(0) { $0 + $1.minutes * 60 },
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

                FocusHeatmap(
                    cells: stats.heatmap(records, weeks: heatmapWeeks, now: now),
                    firstDay: firstDay,
                    palette: palette
                )
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
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
            today = .now
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                today = .now
            }
        }
    }
}
