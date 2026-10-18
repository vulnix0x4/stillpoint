import Foundation

/// Everything needed to bring a running session back after the app is terminated.
nonisolated struct PersistedSession: Codable, Equatable, Sendable {
    var sessionID: UUID
    var plan: SessionPlan
    var clock: SessionClock
    var calm: CalmTracker
    var goalReached: Bool
}
