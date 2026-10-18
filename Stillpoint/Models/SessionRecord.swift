import Foundation

/// A lightweight, persistence-free view of a finished session.
nonisolated struct SessionRecord: Equatable, Sendable {
    var start: Date
    var focused: TimeInterval
    var planned: TimeInterval?
    var depth: Int?
    var outcome: SessionOutcome?
    var usedArrival: Bool
    var thoughtCount: Int

    init(
        start: Date,
        focused: TimeInterval,
        planned: TimeInterval? = nil,
        depth: Int? = nil,
        outcome: SessionOutcome? = nil,
        usedArrival: Bool = false,
        thoughtCount: Int = 0
    ) {
        self.start = start
        self.focused = focused
        self.planned = planned
        self.depth = depth
        self.outcome = outcome
        self.usedArrival = usedArrival
        self.thoughtCount = thoughtCount
    }

    var focusedMinutes: Double { focused / 60 }
}
