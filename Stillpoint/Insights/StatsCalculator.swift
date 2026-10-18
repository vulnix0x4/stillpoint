import Foundation

/// Pure functions that turn session records into totals, streaks and distributions.
///
/// Sessions are attributed to the calendar day on which they started.
nonisolated struct StatsCalculator {
    var calendar: Calendar = .current
    /// Minimum focus on a day for it to count toward a streak.
    var streakThreshold: TimeInterval = 10 * 60

    // MARK: - Days

    func secondsByDay(_ records: [SessionRecord]) -> [Date: TimeInterval] {
        records.reduce(into: [:]) { totals, record in
            totals[calendar.startOfDay(for: record.start), default: 0] += record.focused
        }
    }

    func focusedSeconds(_ records: [SessionRecord], on day: Date) -> TimeInterval {
        records
            .filter { calendar.isDate($0.start, inSameDayAs: day) }
            .reduce(0) { $0 + $1.focused }
    }

    func sessionCount(_ records: [SessionRecord], on day: Date) -> Int {
        records.count { calendar.isDate($0.start, inSameDayAs: day) }
    }

    /// One entry per day for the `days` days ending on `endDay`, oldest first.
    func dailyTotals(_ records: [SessionRecord], days: Int, endingOn endDay: Date) -> [DayTotal] {
        let totals = secondsByDay(records)
        let end = calendar.startOfDay(for: endDay)
        return (0..<days).reversed().compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: end) else { return nil }
            return DayTotal(date: day, minutes: (totals[day] ?? 0) / 60)
        }
    }

    func totalSeconds(_ records: [SessionRecord], in interval: DateInterval) -> TimeInterval {
        records
            .filter { interval.contains($0.start) }
            .reduce(0) { $0 + $1.focused }
    }

    func weekTotal(_ records: [SessionRecord], containing date: Date) -> TimeInterval {
        guard let week = calendar.dateInterval(of: .weekOfYear, for: date) else { return 0 }
        return totalSeconds(records, in: week)
    }

    // MARK: - Streaks

    private func qualifyingDays(_ records: [SessionRecord]) -> Set<Date> {
        Set(secondsByDay(records).filter { $0.value >= streakThreshold }.keys)
    }

    /// Consecutive qualifying days ending today. If today doesn't qualify yet, the streak is
    /// still alive and counted up to yesterday.
    func currentStreak(_ records: [SessionRecord], now: Date) -> Int {
        let days = qualifyingDays(records)
        var day = calendar.startOfDay(for: now)
        if !days.contains(day) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: day) else { return 0 }
            day = yesterday
        }
        var streak = 0
        while days.contains(day) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }
        return streak
    }

    func longestStreak(_ records: [SessionRecord]) -> Int {
        let days = qualifyingDays(records).sorted()
        var longest = 0
        var current = 0
        var previous: Date?
        for day in days {
            if let previous, calendar.date(byAdding: .day, value: 1, to: previous) == day {
                current += 1
            } else {
                current = 1
            }
            longest = max(longest, current)
            previous = day
        }
        return longest
    }

    // MARK: - Quality

    func averageDepth(_ records: [SessionRecord]) -> Double? {
        let ratings = records.compactMap(\.depth)
        guard !ratings.isEmpty else { return nil }
        return Double(ratings.reduce(0, +)) / Double(ratings.count)
    }

    /// Weighted share of intentions met: done counts fully, partly counts half.
    func followThroughRate(_ records: [SessionRecord]) -> Double? {
        let outcomes = records.compactMap(\.outcome)
        guard !outcomes.isEmpty else { return nil }
        return outcomes.reduce(0) { $0 + $1.score } / Double(outcomes.count)
    }

    // MARK: - Distributions

    /// Focused minutes by hour of day. Each session's focus is spread across the wall-clock
    /// hours it covered.
    func hourlyTotals(_ records: [SessionRecord]) -> [HourTotal] {
        var minutes = Array(repeating: 0.0, count: 24)
        for record in records {
            var cursor = record.start
            var remaining = record.focused
            while remaining > 0 {
                let hour = calendar.component(.hour, from: cursor)
                guard let hourStart = calendar.dateInterval(of: .hour, for: cursor) else { break }
                let available = hourStart.end.timeIntervalSince(cursor)
                let slice = min(remaining, max(available, 1))
                minutes[hour] += slice / 60
                remaining -= slice
                cursor = cursor.addingTimeInterval(slice)
            }
        }
        return minutes.enumerated().map { HourTotal(hour: $0.offset, minutes: $0.element) }
    }

    /// Average focused minutes per calendar weekday (1 = Sunday), over days in the range that
    /// had any focus at all.
    func averageMinutesByWeekday(_ records: [SessionRecord]) -> [Int: Double] {
        var sums: [Int: Double] = [:]
        var counts: [Int: Int] = [:]
        for (day, seconds) in secondsByDay(records) {
            let weekday = calendar.component(.weekday, from: day)
            sums[weekday, default: 0] += seconds / 60
            counts[weekday, default: 0] += 1
        }
        return sums.reduce(into: [:]) { result, entry in
            result[entry.key] = entry.value / Double(counts[entry.key] ?? 1)
        }
    }

    /// Columns of seven days (one per week), oldest first. The last column holds today.
    func heatmap(_ records: [SessionRecord], weeks: Int, now: Date) -> [[HeatmapCell]] {
        let totals = secondsByDay(records)
        let today = calendar.startOfDay(for: now)
        guard let thisWeek = calendar.dateInterval(of: .weekOfYear, for: today),
              let firstWeek = calendar.date(byAdding: .weekOfYear, value: -(weeks - 1), to: thisWeek.start)
        else { return [] }

        return (0..<weeks).map { week in
            (0..<7).compactMap { weekday in
                guard let day = calendar.date(byAdding: .day, value: week * 7 + weekday, to: firstWeek) else { return nil }
                return HeatmapCell(date: day, minutes: (totals[day] ?? 0) / 60, isFuture: day > today)
            }
        }
    }
}
