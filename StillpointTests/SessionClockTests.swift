import Foundation
import Testing
@testable import Stillpoint

struct SessionClockTests {
    let start = Date(timeIntervalSinceReferenceDate: 1_000_000)

    @Test func countsDownFromThePlan() {
        let clock = SessionClock(plannedDuration: 1_500, startedAt: start)
        let now = start.addingTimeInterval(600)
        #expect(clock.elapsed(at: now) == 600)
        #expect(clock.remaining(at: now) == 900)
        #expect(clock.progress(at: now) == 0.4)
        #expect(!clock.hasReachedGoal(at: now))
        #expect(clock.goalDate == start.addingTimeInterval(1_500))
    }

    @Test func pausesDoNotCountAsFocus() {
        var clock = SessionClock(plannedDuration: 1_500, startedAt: start)
        clock.pause(at: start.addingTimeInterval(300))
        #expect(clock.isPaused)
        #expect(clock.goalDate == nil)
        #expect(clock.elapsed(at: start.addingTimeInterval(900)) == 300, "Elapsed time is frozen while paused")

        clock.resume(at: start.addingTimeInterval(900))
        #expect(clock.elapsed(at: start.addingTimeInterval(1_000)) == 400)
        #expect(clock.goalDate == start.addingTimeInterval(600 + 1_500))
        #expect(clock.effectiveStart == start.addingTimeInterval(600))
        #expect(clock.pauseCount == 1)
    }

    @Test func doublePauseAndResumeAreIgnored() {
        var clock = SessionClock(plannedDuration: 600, startedAt: start)
        clock.pause(at: start.addingTimeInterval(10))
        clock.pause(at: start.addingTimeInterval(20))
        clock.resume(at: start.addingTimeInterval(30))
        clock.resume(at: start.addingTimeInterval(40))
        #expect(clock.pauseCount == 1)
        #expect(clock.elapsed(at: start.addingTimeInterval(50)) == 30)
    }

    @Test func overtimeAccruesAfterTheGoal() {
        let clock = SessionClock(plannedDuration: 600, startedAt: start)
        let now = start.addingTimeInterval(750)
        #expect(clock.hasReachedGoal(at: now))
        #expect(clock.remaining(at: now) == 0)
        #expect(clock.overtime(at: now) == 150)
        #expect(clock.progress(at: now) == 1)
    }

    @Test func openEndedSessionsHaveNoGoal() {
        let clock = SessionClock(plannedDuration: nil, startedAt: start)
        let now = start.addingTimeInterval(5_400)
        #expect(clock.isOpenEnded)
        #expect(clock.remaining(at: now) == nil)
        #expect(!clock.hasReachedGoal(at: now))
        #expect(clock.overtime(at: now) == 0)
        #expect(clock.progress(at: now) == 0.5, "Progress laps every hour")
    }

    @Test func survivesEncodingRoundTrip() throws {
        var clock = SessionClock(plannedDuration: 900, startedAt: start)
        clock.pause(at: start.addingTimeInterval(100))
        let data = try JSONEncoder().encode(clock)
        let decoded = try JSONDecoder().decode(SessionClock.self, from: data)
        #expect(decoded == clock)
    }
}
