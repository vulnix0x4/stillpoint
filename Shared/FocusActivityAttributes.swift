import ActivityKit
import Foundation

/// Live Activity payload for a running focus session.
nonisolated struct FocusActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable, Sendable {
        enum Phase: String, Codable, Hashable, Sendable {
            case focusing
            case paused
            /// The planned time is up and the person chose to keep going.
            case overtime
        }

        var phase: Phase
        /// When the countdown reaches zero. `nil` for open-ended flow sessions or while paused.
        var goalDate: Date?
        /// Origin for count-up displays, already shifted forward by any paused time.
        var effectiveStart: Date
        /// Seconds to show while paused (remaining for countdowns, elapsed for open sessions).
        var frozenSeconds: TimeInterval
        /// A short human description of how settled the session is, e.g. "Deep focus".
        var depthTitle: String
    }

    var intention: String
    /// Planned length in seconds. `nil` for open-ended flow sessions.
    var plannedDuration: TimeInterval?
    var paletteName: String
}
