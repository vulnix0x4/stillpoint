import SwiftUI

/// Four headline numbers.
struct SummaryGrid: View {
    var today: TimeInterval
    var streak: Int
    var longestStreak: Int
    var week: TimeInterval
    var averageDepth: Double?

    var body: some View {
        Grid(horizontalSpacing: Theme.Spacing.small, verticalSpacing: Theme.Spacing.small) {
            GridRow {
                StatTile(title: "Today", value: TimeText.short(today), symbol: "sun.max")
                StatTile(
                    title: "Streak",
                    value: streak == 1 ? "1 day" : "\(streak) days",
                    symbol: "flame",
                    footnote: longestStreak > streak ? "Best: \(longestStreak)" : nil
                )
            }
            GridRow {
                StatTile(title: "Last 7 days", value: TimeText.short(week), symbol: "calendar")
                StatTile(
                    title: "Average depth",
                    value: averageDepth.map { $0.formatted(.number.precision(.fractionLength(1))) } ?? "–",
                    symbol: "circle.hexagongrid",
                    footnote: averageDepth == nil ? nil : "out of 5"
                )
            }
        }
    }
}
