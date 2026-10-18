import Foundation
import SwiftData

/// One focus session, from the moment focus began to the reflection afterwards.
@Model
final class FocusSession {
    var id: UUID = UUID()
    var startDate: Date = Date.now
    var endDate: Date = Date.now
    /// Planned length in seconds; `nil` for open-ended flow sessions.
    var plannedDuration: TimeInterval?
    /// Seconds actually spent focusing, excluding pauses.
    var focusedDuration: TimeInterval = 0
    var intention: String = ""
    var outcomeRawValue: String?
    /// Self-reported depth, 1 (scattered) to 5 (absorbed).
    var depthRating: Int?
    var note: String = ""
    var soundscapeName: String?
    var usedArrival: Bool = false
    var pauseCount: Int = 0
    var reachedGoal: Bool = false
    /// The longest unbroken stretch of calm focus, in seconds.
    var longestCalmStretch: TimeInterval = 0
    /// `false` while the session is running or awaiting reflection. Only finalized
    /// sessions count toward stats.
    var isFinalized: Bool = false

    @Relationship(deleteRule: .nullify, inverse: \ParkedThought.session)
    var thoughts: [ParkedThought]? = []

    init(
        startDate: Date,
        plannedDuration: TimeInterval?,
        intention: String,
        usedArrival: Bool,
        soundscapeName: String?
    ) {
        self.startDate = startDate
        self.endDate = startDate
        self.plannedDuration = plannedDuration
        self.intention = intention
        self.usedArrival = usedArrival
        self.soundscapeName = soundscapeName
    }

    var outcome: SessionOutcome? {
        get { outcomeRawValue.flatMap(SessionOutcome.init(rawValue:)) }
        set { outcomeRawValue = newValue?.rawValue }
    }

    var sortedThoughts: [ParkedThought] {
        (thoughts ?? []).sorted { $0.createdAt < $1.createdAt }
    }

    /// A plain value copy used by the stats and insight engines.
    var record: SessionRecord {
        SessionRecord(
            start: startDate,
            focused: focusedDuration,
            planned: plannedDuration,
            depth: depthRating,
            outcome: outcome,
            usedArrival: usedArrival,
            thoughtCount: thoughts?.count ?? 0
        )
    }
}
