import Foundation

/// Everything needed to bring a running session back after the app is terminated.
nonisolated struct PersistedSession: Codable, Equatable, Sendable {
    var sessionID: UUID
    var plan: SessionPlan
    var clock: SessionClock
    var calm: CalmTracker
    var goalReached: Bool
    /// `true` once focus has ended and only the reflection remains. Optional so data written
    /// by earlier versions still decodes.
    var isReflecting: Bool?
    /// The last moment the app was known to be running this session.
    var lastSeenAt: Date?
}
