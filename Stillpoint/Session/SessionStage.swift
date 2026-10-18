import Foundation

/// Where the app is in the life of a session.
nonisolated enum SessionStage: Equatable, Sendable {
    case idle
    /// A short guided breath before focus begins.
    case arriving
    case focusing
    /// Focus has ended and the person is reflecting on it.
    case reflecting
}
