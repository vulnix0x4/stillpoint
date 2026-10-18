import Foundation
import Testing
@testable import Stillpoint

struct InsightGeneratorTests {
    let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }()

    var now: Date {
        calendar.date(from: DateComponents(year: 2025, month: 10, day: 15, hour: 20)) ?? .now
    }

    var generator: InsightGenerator {
        InsightGenerator(calendar: calendar, locale: Locale(identifier: "en_US"))
    }

    func session(daysAgo: Int, hour: Int, minutes: Double, depth: Int? = nil, outcome: SessionOutcome? = nil, arrival: Bool = false, thoughts: Int = 0) -> SessionRecord {
        let base = calendar.date(byAdding: .day, value: -daysAgo, to: now) ?? now
        let start = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: base) ?? base
        return SessionRecord(start: start, focused: minutes * 60, depth: depth, outcome: outcome, usedArrival: arrival, thoughtCount: thoughts)
    }

    @Test func staysQuietWithLittleData() {
        let records = [session(daysAgo: 0, hour: 9, minutes: 25, depth: 4)]
        #expect(generator.insights(for: records, now: now).isEmpty)
    }

    @Test func findsThePeakWindow() throws {
        let records = (0..<6).map { session(daysAgo: $0, hour: 9, minutes: 50) } + [session(daysAgo: 1, hour: 15, minutes: 20)]
        let insight = try #require(generator.peakWindow(records))
        #expect(insight.title.contains("9"))
        #expect(insight.title.contains("11"))
    }

    @Test func noticesLongerSessionsRunDeeper() throws {
        let long = (0..<3).map { session(daysAgo: $0, hour: 9, minutes: 60, depth: 5) }
        let short = (0..<3).map { session(daysAgo: $0, hour: 14, minutes: 20, depth: 3) }
        let insight = try #require(generator.lengthAndDepth(long + short))
        #expect(insight.title == "Longer sessions run deeper")
    }

    @Test func noticesBreathingHelps() throws {
        let with = (0..<3).map { session(daysAgo: $0, hour: 9, minutes: 30, depth: 5, arrival: true) }
        let without = (0..<3).map { session(daysAgo: $0, hour: 14, minutes: 30, depth: 3) }
        let insight = try #require(generator.arrivalEffect(with + without))
        #expect(insight.detail.contains("2.0"))
    }

    @Test func doesNotClaimBreathingHelpsWhenItDoesnt() {
        let with = (0..<3).map { session(daysAgo: $0, hour: 9, minutes: 30, depth: 3, arrival: true) }
        let without = (0..<3).map { session(daysAgo: $0, hour: 14, minutes: 30, depth: 4) }
        #expect(generator.arrivalEffect(with + without) == nil)
    }

    @Test func reportsMomentum() throws {
        let previous = (8..<14).map { session(daysAgo: $0, hour: 9, minutes: 30) }
        let recent = (0..<7).map { session(daysAgo: $0, hour: 9, minutes: 60) }
        let insight = try #require(generator.momentum(previous + recent, now: now))
        #expect(insight.title == "Momentum is building")
    }

    @Test func countsParkedThoughts() throws {
        let records = (0..<3).map { session(daysAgo: $0, hour: 9, minutes: 30, thoughts: 2) }
        let insight = try #require(generator.parkedThoughts(records))
        #expect(insight.title.hasPrefix("6 thoughts"))
    }

    @Test func followThroughNeedsFiveOutcomes() {
        let four = (0..<4).map { session(daysAgo: $0, hour: 9, minutes: 30, outcome: .achieved) }
        #expect(generator.followThrough(four) == nil)
        let five = four + [session(daysAgo: 5, hour: 9, minutes: 30, outcome: .achieved)]
        #expect(generator.followThrough(five)?.title.contains("100%") == true)
    }
}
