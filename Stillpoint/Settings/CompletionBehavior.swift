import Foundation

/// What happens when the planned time runs out.
enum CompletionBehavior: String, CaseIterable, Identifiable {
    /// Ring the bell and keep counting, so a good flow state is never cut off.
    case keepFlowing
    /// Ring the bell and move straight to reflection.
    case endSession

    var id: String { rawValue }

    var title: String {
        switch self {
        case .keepFlowing: "Keep flowing"
        case .endSession: "End the session"
        }
    }
}
