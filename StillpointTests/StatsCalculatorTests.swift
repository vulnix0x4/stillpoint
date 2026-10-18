import Foundation
import Testing
@testable import Stillpoint

struct StatsCalculatorTests {
    let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/London") ?? .gmt
        calendar.firstWeekday = 2
        return calendar
    }()

    /// Wednesday 15 October 2025, 18:00 in London.
    var now: Date {
        calendar.date(from: DateComponents(year: 2025, month: 10, day: 15, hour: 18)) ?? .now
    }

    func day(_ offset: Int, hour: Int = 9) -> Date {
        let base = calendar.date(byAdding: .day, value: offset, to: calendar.startOfDay(for: now)) ?? now
        return calendar.date(bySettingHour: hour, minute: 0, second: 0, of: base) ?? base
    }

    var stats: StatsCalculator {
        StatsCalculator(calendar: calendar)
    }

    @Test func streakCountsBackFromToday() {
        let records = [0, -1, -2, -4].map { SessionRecord(start: day($0), focused: 1_800) }
        #expect(stats.currentStreak(records, now: now) == 3)
    }

    @Test func streakSurvivesUntilTodayEnds() {
        let records = [-1, -2].map { SessionRecord(start: day($0), focused: 1_800) }
        #expect(stats.currentStreak(records, now: now) == 2)
    }

    @Test func streakBreaksAfterAMissedDay() {
        let records = [-2, -3].map { SessionRecord(start: day($0), focused: 1_800) }
        #expect(stats.currentStreak(records, now: now) == 0)
    }

    @Test func shortDaysDoNotCount() {
        let records = [SessionRecord(start: day(0), focused: 300), SessionRecord(start: day(-1), focused: 1_200)]
        #expect(stats.currentStreak(records, now: now) == 1)
    }

    @Test func longestStreakFindsTheBestRun() {
        let records = [-10, -9, -8, -7, -3, -2].map { SessionRecord(start: day($0), focused: 900) }
        #expect(stats.longestStreak(records) == 4)
    }

    @Test func dailyTotalsAreOldestFirstAndIncludeEmptyDays() {
        let records = [
            SessionRecord(start: day(0), focused: 1_800),
            SessionRecord(start: day(0, hour: 14), focused: 600),
            SessionRecord(start: day(-2), focused: 3_000),
        ]
        let totals = stats.dailyTotals(records, days: 3, endingOn: now)
        #expect(totals.map(\.minutes) == [50, 0, 40])
        #expect(totals.last?.date == calendar.startOfDay(for: now))
    }

    @Test func hourlyTotalsSplitSessionsAcrossHours() {
        let start = calendar.date(bySettingHour: 9, minute: 30, second: 0, of: now) ?? now
        let hours = stats.hourlyTotals([SessionRecord(start: start, focused: 3_600)])
        #expect(hours[9].minutes == 30)
        #expect(hours[10].minutes == 30)
        #expect(hours.reduce(0) { $0 + $1.minutes } == 60)
    }

    @Test func heatmapEndsWithTheCurrentWeek() {
        let records = [SessionRecord(start: day(0), focused: 6_000)]
        let columns = stats.heatmap(records, weeks: 4, now: now)
        #expect(columns.count == 4)
        #expect(columns.allSatisfy { $0.count == 7 })
        let todayCell = columns.last?.first { calendar.isDate($0.date, inSameDayAs: now) }
        #expect(todayCell?.minutes == 100)
        #expect(todayCell?.level == 3)
        // Wednesday with Monday-first weeks: Thursday onwards is in the future.
        #expect(columns.last?.filter(\.isFuture).count == 4)
    }

    @Test func weekTotalUsesTheCalendarWeek() {
        let records = [
            SessionRecord(start: day(0), focused: 600),
            SessionRecord(start: day(-2), focused: 600),
            SessionRecord(start: day(-3), focused: 600),
        ]
        // Monday is two days before Wednesday, so Sunday (-3) is last week.
        #expect(stats.weekTotal(records, containing: now) == 1_200)
    }

    @Test func followThroughWeighsPartialOutcomes() {
        let records = [
            SessionRecord(start: day(0), focused: 600, outcome: .achieved),
            SessionRecord(start: day(0), focused: 600, outcome: .partly),
            SessionRecord(start: day(0), focused: 600, outcome: .notYet),
            SessionRecord(start: day(0), focused: 600),
        ]
        #expect(stats.followThroughRate(records) == 0.5)
    }

    @Test func averageDepthIgnoresUnratedSessions() {
        let records = [
            SessionRecord(start: day(0), focused: 600, depth: 4),
            SessionRecord(start: day(0), focused: 600, depth: 2),
            SessionRecord(start: day(0), focused: 600),
        ]
        #expect(stats.averageDepth(records) == 3)
        #expect(stats.averageDepth([]) == nil)
    }

    @Test func streaksSurviveDaylightSavingStartingAtMidnight() throws {
        // In Santiago the clocks jumped from 00:00 to 01:00 on 7 September 2025.
        var santiago = Calendar(identifier: .gregorian)
        santiago.timeZone = try #require(TimeZone(identifier: "America/Santiago"))
        let stats = StatsCalculator(calendar: santiago)
        func noon(_ day: Int) -> Date {
            santiago.date(from: DateComponents(year: 2025, month: 9, day: day, hour: 12)) ?? .now
        }
        let records = [6, 7, 8].map { SessionRecord(start: noon($0), focused: 1_800) }
        #expect(stats.currentStreak(records, now: noon(8)) == 3)
        #expect(stats.longestStreak(records) == 3)
        #expect(stats.dailyTotals(records, days: 3, endingOn: noon(8)).map(\.minutes) == [30, 30, 30])
    }
}
