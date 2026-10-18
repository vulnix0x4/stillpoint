import Foundation

/// How a session's intention turned out, as judged by the person afterwards.
nonisolated enum SessionOutcome: String, CaseIterable, Identifiable, Codable, Sendable {
    case achieved
    case partly
    case notYet

    var id: String { rawValue }

    var title: String {
        switch self {
        case .achieved: "Done"
        case .partly: "Partly"
        case .notYet: "Not yet"
        }
    }

    var symbol: String {
        switch self {
        case .achieved: "checkmark.circle.fill"
        case .partly: "circle.lefthalf.filled"
        case .notYet: "circle.dashed"
        }
    }

    /// Weight used when computing follow-through rates.
    var score: Double {
        switch self {
        case .achieved: 1
        case .partly: 0.5
        case .notYet: 0
        }
    }
}
