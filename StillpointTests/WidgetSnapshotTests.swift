import Foundation
import Testing
@testable import Stillpoint

struct WidgetSnapshotTests {
    let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }()

    func date(day: Int, hour: Int) -> Date {
        calendar.date(from: DateComponents(year: 2025, month: 10, day: day, hour: hour)) ?? .now
    }

    var snapshot: WidgetSnapshot {
        WidgetSnapshot(
            computedAt: date(day: 15, hour: 20),
            todayMinutes: 90,
            goalMinutes: 120,
            streakDays: 4,
            todayCountsTowardStreak: true,
            sessionsToday: 3,
            paletteName: "tide",
            lastSevenDays: [10, 20, 30, 40, 50, 60, 90]
        )
    }

    @Test func sameDayIsUnchanged() {
        #expect(snapshot.adjusted(to: date(day: 15, hour: 23), calendar: calendar) == snapshot)
    }

    @Test func nextDayResetsTodayButKeepsTheStreak() {
        let adjusted = snapshot.adjusted(to: date(day: 16, hour: 8), calendar: calendar)
        #expect(adjusted.todayMinutes == 0)
        #expect(adjusted.sessionsToday == 0)
        #expect(adjusted.streakDays == 4)
        #expect(adjusted.lastSevenDays == [20, 30, 40, 50, 60, 90, 0])
    }

    @Test func aMissedDayBreaksTheStreak() {
        let adjusted = snapshot.adjusted(to: date(day: 17, hour: 8), calendar: calendar)
        #expect(adjusted.streakDays == 0)
        #expect(adjusted.lastSevenDays == [30, 40, 50, 60, 90, 0, 0])
    }

    @Test func goalProgressIsClamped() {
        var full = snapshot
        full.todayMinutes = 500
        #expect(full.goalProgress == 1)
        #expect(snapshot.goalProgress == 0.75)
    }
}
