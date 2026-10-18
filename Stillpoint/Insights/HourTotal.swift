import Foundation

/// Focused minutes that fell within one hour of the day, across all sessions.
nonisolated struct HourTotal: Identifiable, Equatable, Sendable {
    /// 0...23
    var hour: Int
    var minutes: Double

    var id: Int { hour }
}
