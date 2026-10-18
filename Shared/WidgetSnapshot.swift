import Foundation

/// A small summary of today's focus that the app writes for its widgets to read.
nonisolated struct WidgetSnapshot: Codable, Equatable, Sendable {
    /// The moment this snapshot was computed.
    var computedAt: Date
    var todayMinutes: Int
    var goalMinutes: Int
    var streakDays: Int
    /// Whether today already counts toward the streak.
    var todayCountsTowardStreak: Bool
    var sessionsToday: Int
    var paletteName: String
    /// Minutes per day for the last seven days, oldest first, ending with the day of `computedAt`.
    var lastSevenDays: [Int]

    private static let storageKey = "widgetSnapshot.v1"

    static let placeholder = WidgetSnapshot(
        computedAt: .now,
        todayMinutes: 75,
        goalMinutes: 120,
        streakDays: 6,
        todayCountsTowardStreak: true,
        sessionsToday: 3,
        paletteName: OrbPalette.ember.rawValue,
        lastSevenDays: [90, 45, 120, 0, 140, 60, 75]
    )

    static let empty = WidgetSnapshot(
        computedAt: .now,
        todayMinutes: 0,
        goalMinutes: 120,
        streakDays: 0,
        todayCountsTowardStreak: false,
        sessionsToday: 0,
        paletteName: OrbPalette.ember.rawValue,
        lastSevenDays: Array(repeating: 0, count: 7)
    )

    var goalProgress: Double {
        guard goalMinutes > 0 else { return 0 }
        return min(1, Double(todayMinutes) / Double(goalMinutes))
    }

    /// Re-bases a snapshot that may have been written on an earlier day, so a widget
    /// rendered after midnight doesn't keep showing yesterday's numbers.
    func adjusted(to now: Date, calendar: Calendar = .current) -> WidgetSnapshot {
        let snapshotDay = calendar.startOfDay(for: computedAt)
        let today = calendar.startOfDay(for: now)
        let dayGap = calendar.dateComponents([.day], from: snapshotDay, to: today).day ?? 0
        guard dayGap > 0 else { return self }

        var copy = self
        copy.computedAt = now
        copy.todayMinutes = 0
        copy.sessionsToday = 0
        copy.todayCountsTowardStreak = false
        // A streak survives one quiet day only if the snapshot day itself counted.
        if dayGap > 1 || !todayCountsTowardStreak {
            copy.streakDays = 0
        }
        let shift = min(dayGap, 7)
        copy.lastSevenDays = Array(lastSevenDays.dropFirst(shift)) + Array(repeating: 0, count: shift)
        return copy
    }

    static func load(from defaults: UserDefaults = AppGroup.defaults) -> WidgetSnapshot? {
        guard let data = defaults.data(forKey: storageKey) else { return nil }
        return try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
    }

    func save(to defaults: UserDefaults = AppGroup.defaults) {
        guard let data = try? JSONEncoder().encode(self) else { return }
        defaults.set(data, forKey: Self.storageKey)
    }
}
