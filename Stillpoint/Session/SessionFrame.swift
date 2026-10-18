import Foundation

/// Everything the session screen needs to draw a single frame.
nonisolated struct SessionFrame: Equatable, Sendable {
    var elapsed: TimeInterval
    /// `nil` for open-ended sessions.
    var remaining: TimeInterval?
    var overtime: TimeInterval
    var progress: Double
    var isPaused: Bool
    var isOpenEnded: Bool
    var goalReached: Bool
    var depth: FocusDepth
    var turbulence: Double
    var energy: Double

    static let idle = SessionFrame(
        elapsed: 0, remaining: nil, overtime: 0, progress: 0, isPaused: false,
        isOpenEnded: true, goalReached: false, depth: .settling, turbulence: 0.5, energy: 0
    )

    init(
        elapsed: TimeInterval, remaining: TimeInterval?, overtime: TimeInterval, progress: Double,
        isPaused: Bool, isOpenEnded: Bool, goalReached: Bool, depth: FocusDepth,
        turbulence: Double, energy: Double
    ) {
        self.elapsed = elapsed
        self.remaining = remaining
        self.overtime = overtime
        self.progress = progress
        self.isPaused = isPaused
        self.isOpenEnded = isOpenEnded
        self.goalReached = goalReached
        self.depth = depth
        self.turbulence = turbulence
        self.energy = energy
    }

    init(clock: SessionClock, calm: CalmTracker, goalReached: Bool, at now: Date) {
        let elapsed = clock.elapsed(at: now)
        let calmSeconds = calm.calmSeconds(atElapsed: elapsed)
        let reached = goalReached || clock.hasReachedGoal(at: now)

        var energy = 0.0
        if reached {
            // A gentle, slow pulse once the goal is behind you.
            energy = 0.28 + 0.12 * sin(now.timeIntervalSinceReferenceDate * 0.7)
        }

        self.init(
            elapsed: elapsed,
            remaining: clock.remaining(at: now),
            overtime: clock.overtime(at: now),
            progress: clock.progress(at: now),
            isPaused: clock.isPaused,
            isOpenEnded: clock.isOpenEnded,
            goalReached: reached,
            depth: FocusDepth(calmSeconds: calmSeconds),
            turbulence: clock.isPaused ? 0.55 : FocusDepth.turbulence(calmSeconds: calmSeconds),
            energy: energy
        )
    }
}
