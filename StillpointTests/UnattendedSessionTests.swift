import Foundation
import Testing
@testable import Stillpoint

/// Rules for sessions left running while nobody was there.
struct UnattendedSessionTests {
    let start = Date(timeIntervalSinceReferenceDate: 2_000_000)

    func clock(planned: TimeInterval?) -> SessionClock {
        SessionClock(plannedDuration: planned, startedAt: start)
    }

    @Test func aCountdownShortOfItsGoalCarriesOn() {
        let ended = SessionEngine.unattendedEnd(of: clock(planned: 3_600), lastSeen: start, now: start.addingTimeInterval(3_000))
        #expect(ended == nil)
    }

    @Test func recentlyAttendedOvertimeCarriesOn() {
        let now = start.addingTimeInterval(1_500 + 600)
        let ended = SessionEngine.unattendedEnd(of: clock(planned: 1_500), lastSeen: now.addingTimeInterval(-60), now: now)
        #expect(ended == nil)
    }

    @Test func passingTheGoalUnattendedEndsAtTheGoal() {
        let now = start.addingTimeInterval(1_500 + 2_400)
        let ended = SessionEngine.unattendedEnd(of: clock(planned: 1_500), lastSeen: start.addingTimeInterval(120), now: now)
        #expect(ended == start.addingTimeInterval(1_500))
    }

    @Test func overtimeIsCapped() {
        // Attended the whole time, but three hours past a 25-minute goal.
        let now = start.addingTimeInterval(1_500 + 3 * 3_600)
        let ended = SessionEngine.unattendedEnd(of: clock(planned: 1_500), lastSeen: now, now: now)
        #expect(ended == start.addingTimeInterval(1_500 + 3_600))
    }

    @Test func longPlansGetALongerOvertimeCap() {
        #expect(SessionEngine.overtimeCap(for: 5_400) == 5_400)
        #expect(SessionEngine.overtimeCap(for: 900) == 3_600)
    }

    @Test func openEndedSessionsStopAfterFourHours() {
        let flow = clock(planned: nil)
        #expect(SessionEngine.unattendedEnd(of: flow, lastSeen: start, now: start.addingTimeInterval(3 * 3_600)) == nil)
        #expect(SessionEngine.unattendedEnd(of: flow, lastSeen: start, now: start.addingTimeInterval(5 * 3_600)) == start.addingTimeInterval(4 * 3_600))
    }

    @Test func pausedSessionsAreLeftAlone() {
        var paused = clock(planned: 600)
        paused.pause(at: start.addingTimeInterval(60))
        #expect(SessionEngine.unattendedEnd(of: paused, lastSeen: start, now: start.addingTimeInterval(10 * 3_600)) == nil)
    }
}
