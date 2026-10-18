import Foundation

/// Guided breathing patterns used to arrive before a session, or on their own.
nonisolated enum BreathPattern: String, CaseIterable, Identifiable, Codable, Sendable {
    case sigh
    case box
    case coherent
    case relax478

    var id: String { rawValue }

    var title: String {
        switch self {
        case .sigh: "Physiological sigh"
        case .box: "Box breathing"
        case .coherent: "Coherent breathing"
        case .relax478: "4-7-8"
        }
    }

    var summary: String {
        switch self {
        case .sigh: "Two inhales, one long exhale. A quick way to settle."
        case .box: "In, hold, out, hold. Four counts each."
        case .coherent: "Slow, even breaths at about five and a half a minute."
        case .relax478: "A long hold and a longer exhale to downshift."
        }
    }

    var phases: [BreathPhase] {
        switch self {
        case .sigh: [.inhale(2.2, to: 0.75), .topUp(1.0, from: 0.75), .exhale(6.5)]
        case .box: [.inhale(4), .hold(4), .exhale(4), .rest(4)]
        case .coherent: [.inhale(5.5), .exhale(5.5)]
        case .relax478: [.inhale(4), .hold(7), .exhale(8)]
        }
    }

    var cycleDuration: TimeInterval {
        phases.reduce(0) { $0 + $1.duration }
    }

    /// The number of whole cycles needed to fill at least `duration` seconds.
    func cycles(toFill duration: TimeInterval) -> Int {
        max(1, Int((duration / cycleDuration).rounded(.up)))
    }
}
