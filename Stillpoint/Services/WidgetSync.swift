import Foundation
import SwiftData
import WidgetKit

/// Writes a fresh `WidgetSnapshot` and asks WidgetKit to redraw.
enum WidgetSync {
    static func refresh(using context: ModelContext, defaults: UserDefaults = .standard, now: Date = .now) {
        let descriptor = FetchDescriptor<FocusSession>(predicate: #Predicate { $0.isFinalized })
        guard let sessions = try? context.fetch(descriptor) else { return }
        let records = sessions.map(\.record)
        let stats = StatsCalculator()
        let today = stats.focusedSeconds(records, on: now)

        let snapshot = WidgetSnapshot(
            computedAt: now,
            todayMinutes: Int(today / 60),
            goalMinutes: defaults.integer(forKey: PreferenceKey.dailyGoalMinutes, default: PreferenceKey.Default.dailyGoalMinutes),
            streakDays: stats.currentStreak(records, now: now),
            todayCountsTowardStreak: today >= stats.streakThreshold,
            sessionsToday: stats.sessionCount(records, on: now),
            paletteName: defaults.string(forKey: PreferenceKey.palette) ?? OrbPalette.ember.rawValue,
            lastSevenDays: stats.dailyTotals(records, days: 7, endingOn: now).map { Int($0.minutes) }
        )
        snapshot.save()
        WidgetCenter.shared.reloadAllTimelines()
    }
}
