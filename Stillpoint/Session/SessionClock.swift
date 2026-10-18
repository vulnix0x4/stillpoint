import Foundation

/// Wall-clock based timekeeping for a session.
///
/// Nothing here ticks: every value is derived from the start date and the pauses taken, so
/// the clock stays correct across backgrounding, suspension, and even relaunches.
nonisolated struct SessionClock: Codable, Equatable, Sendable {
    /// Planned length in seconds; `nil` for open-ended flow sessions.
    let plannedDuration: TimeInterval?
    let startedAt: Date
    private(set) var pausedAt: Date?
    private(set) var totalPaused: TimeInterval = 0
    private(set) var pauseCount = 0

    init(plannedDuration: TimeInterval?, startedAt: Date) {
        self.plannedDuration = plannedDuration
        self.startedAt = startedAt
    }

    var isOpenEnded: Bool { plannedDuration == nil }
    var isPaused: Bool { pausedAt != nil }

    /// Focused seconds so far, excluding pauses.
    func elapsed(at now: Date) -> TimeInterval {
        let reference = pausedAt ?? now
        return max(0, reference.timeIntervalSince(startedAt) - totalPaused)
    }

    /// Seconds left before the planned goal, clamped at zero. `nil` for open-ended sessions.
    func remaining(at now: Date) -> TimeInterval? {
        plannedDuration.map { max(0, $0 - elapsed(at: now)) }
    }

    /// Seconds spent beyond the planned goal.
    func overtime(at now: Date) -> TimeInterval {
        guard let plannedDuration else { return 0 }
        return max(0, elapsed(at: now) - plannedDuration)
    }

    func hasReachedGoal(at now: Date) -> Bool {
        guard let plannedDuration else { return false }
        return elapsed(at: now) >= plannedDuration
    }

    /// Fraction of the plan completed. Open-ended sessions report progress through the current hour.
    func progress(at now: Date) -> Double {
        let elapsed = elapsed(at: now)
        guard let plannedDuration, plannedDuration > 0 else {
            return elapsed.truncatingRemainder(dividingBy: 3600) / 3600
        }
        return min(1, elapsed / plannedDuration)
    }

    /// When the countdown reaches zero if it keeps running. `nil` while paused or open-ended.
    var goalDate: Date? {
        guard let plannedDuration, !isPaused else { return nil }
        return startedAt.addingTimeInterval(totalPaused + plannedDuration)
    }

    /// The start date shifted forward by paused time, for count-up displays.
    var effectiveStart: Date {
        startedAt.addingTimeInterval(totalPaused)
    }

    mutating func pause(at now: Date) {
        guard pausedAt == nil else { return }
        pausedAt = now
        pauseCount += 1
    }

    mutating func resume(at now: Date) {
        guard let pausedAt else { return }
        totalPaused += max(0, now.timeIntervalSince(pausedAt))
        self.pausedAt = nil
    }
}
