import Foundation

/// Models how settled attention is during a session.
///
/// Calm accrues with uninterrupted focus time. Parking a thought costs half of the current
/// calm (noticing and setting a thought aside is far better than following it), while a
/// pause breaks the stretch entirely. All values are in focus-elapsed seconds, so paused
/// time never counts.
nonisolated struct CalmTracker: Codable, Equatable, Sendable {
    /// The focus-elapsed value at which the current calm stretch effectively began.
    private(set) var anchor: TimeInterval = 0
    private(set) var longestStretch: TimeInterval = 0

    func calmSeconds(atElapsed elapsed: TimeInterval) -> TimeInterval {
        max(0, elapsed - anchor)
    }

    func longest(atElapsed elapsed: TimeInterval) -> TimeInterval {
        max(longestStretch, calmSeconds(atElapsed: elapsed))
    }

    mutating func noteThoughtParked(atElapsed elapsed: TimeInterval) {
        let calm = calmSeconds(atElapsed: elapsed)
        longestStretch = max(longestStretch, calm)
        anchor += calm / 2
    }

    mutating func noteResumed(atElapsed elapsed: TimeInterval) {
        longestStretch = max(longestStretch, calmSeconds(atElapsed: elapsed))
        anchor = elapsed
    }
}
