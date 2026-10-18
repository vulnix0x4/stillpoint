import Foundation

/// What the person chose before beginning a session.
nonisolated struct SessionPlan: Codable, Equatable, Sendable {
    var intention: String
    /// Planned minutes, or `nil` for an open-ended flow session.
    var plannedMinutes: Int?
    var arriveFirst: Bool
    var breathPattern: BreathPattern

    init(intention: String = "", plannedMinutes: Int? = 25, arriveFirst: Bool = false, breathPattern: BreathPattern = .sigh) {
        self.intention = intention.trimmingCharacters(in: .whitespacesAndNewlines)
        self.plannedMinutes = plannedMinutes
        self.arriveFirst = arriveFirst
        self.breathPattern = breathPattern
    }

    var plannedDuration: TimeInterval? {
        plannedMinutes.map { TimeInterval($0) * LaunchArguments.secondsPerMinute }
    }
}
