import Foundation

/// Focused minutes on one calendar day.
nonisolated struct DayTotal: Identifiable, Equatable, Sendable {
    /// Start of the day.
    var date: Date
    var minutes: Double

    var id: Date { date }
}
