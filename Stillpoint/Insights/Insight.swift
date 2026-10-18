import Foundation

/// A single observation about the person's focus patterns.
nonisolated struct Insight: Identifiable, Equatable, Sendable {
    var id: String
    var symbol: String
    var title: String
    var detail: String
}
