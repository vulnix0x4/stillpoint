import Foundation

/// The three stages a session moves through as attention settles.
///
/// Thresholds loosely follow the common observation that it takes several minutes of
/// uninterrupted work to get absorbed, and around a quarter of an hour to reach real depth.
nonisolated enum FocusDepth: Int, CaseIterable, Comparable, Codable, Sendable {
    case settling
    case focused
    case deep

    static let focusedThreshold: TimeInterval = 5 * 60
    static let deepThreshold: TimeInterval = 15 * 60

    init(calmSeconds: TimeInterval) {
        self = switch calmSeconds {
        case ..<Self.focusedThreshold: .settling
        case ..<Self.deepThreshold: .focused
        default: .deep
        }
    }

    var title: String {
        switch self {
        case .settling: "Settling in"
        case .focused: "Focused"
        case .deep: "Deep focus"
        }
    }

    var guidance: String {
        switch self {
        case .settling: "Let the noise fade. Stay with the first small step."
        case .focused: "You're in. Keep hold of the thread."
        case .deep: "Protect this. Everything else can wait."
        }
    }

    static func < (lhs: FocusDepth, rhs: FocusDepth) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    /// 0 when a stretch begins, approaching 1 after roughly a quarter of an hour.
    static func stillness(calmSeconds: TimeInterval) -> Double {
        1 - exp(-max(0, calmSeconds) / 300)
    }

    /// Visual turbulence for the orb: restless at first, calm when deep.
    static func turbulence(calmSeconds: TimeInterval) -> Double {
        0.1 + 0.9 * (1 - stillness(calmSeconds: calmSeconds))
    }
}
