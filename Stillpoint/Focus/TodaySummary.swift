import Foundation

/// Today's headline numbers for the home screen.
nonisolated struct TodaySummary: Equatable, Sendable {
    var minutes: Int
    var sessions: Int
    var streak: Int

    init(records: [SessionRecord], now: Date, calculator: StatsCalculator = StatsCalculator()) {
        minutes = Int(calculator.focusedSeconds(records, on: now) / 60)
        sessions = calculator.sessionCount(records, on: now)
        streak = calculator.currentStreak(records, now: now)
    }
}
