import Foundation

/// One step of a breathing pattern, e.g. "inhale for four seconds".
nonisolated struct BreathPhase: Equatable, Sendable {
    enum Kind: Equatable, Sendable {
        case inhale
        /// A short second inhale on top of the first, as in the physiological sigh.
        case topUp
        case hold
        case exhale
        /// A pause with empty lungs.
        case rest
    }

    var kind: Kind
    var duration: TimeInterval
    /// Lung "fullness" at the start and end of the phase, 0...1. Drives the orb's size.
    var from: Double
    var to: Double

    var prompt: String {
        switch kind {
        case .inhale: "Breathe in"
        case .topUp: "In again"
        case .hold: "Hold"
        case .exhale: "Let it go"
        case .rest: "Rest"
        }
    }

    static func inhale(_ duration: TimeInterval, to: Double = 1) -> BreathPhase {
        BreathPhase(kind: .inhale, duration: duration, from: 0, to: to)
    }

    static func topUp(_ duration: TimeInterval, from: Double) -> BreathPhase {
        BreathPhase(kind: .topUp, duration: duration, from: from, to: 1)
    }

    static func hold(_ duration: TimeInterval) -> BreathPhase {
        BreathPhase(kind: .hold, duration: duration, from: 1, to: 1)
    }

    static func exhale(_ duration: TimeInterval) -> BreathPhase {
        BreathPhase(kind: .exhale, duration: duration, from: 1, to: 0)
    }

    static func rest(_ duration: TimeInterval) -> BreathPhase {
        BreathPhase(kind: .rest, duration: duration, from: 0, to: 0)
    }
}
