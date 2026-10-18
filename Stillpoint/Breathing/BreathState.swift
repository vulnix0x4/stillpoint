import Foundation

/// Where a breathing exercise is at a given moment.
nonisolated struct BreathState: Equatable, Sendable {
    /// Zero-based index of the current cycle.
    var cycle: Int
    var phaseIndex: Int
    var phase: BreathPhase
    /// Progress through the current phase, 0...1.
    var phaseProgress: Double
    /// Seconds left in the current phase.
    var phaseRemaining: TimeInterval
    /// Eased lung fullness, 0...1.
    var fullness: Double

    /// Computes the state of `pattern` after `elapsed` seconds.
    init(pattern: BreathPattern, elapsed: TimeInterval) {
        let phases = pattern.phases
        let cycleDuration = pattern.cycleDuration
        let clamped = max(0, elapsed)
        cycle = Int(clamped / cycleDuration)
        var offset = clamped - Double(cycle) * cycleDuration

        var index = 0
        while index < phases.count - 1, offset >= phases[index].duration {
            offset -= phases[index].duration
            index += 1
        }

        let phase = phases[index]
        let progress = min(1, max(0, offset / phase.duration))
        phaseIndex = index
        self.phase = phase
        phaseProgress = progress
        phaseRemaining = max(0, phase.duration - offset)

        // Cosine easing mimics the way lungs slow at the top and bottom of a breath.
        let eased = 0.5 - 0.5 * cos(Double.pi * progress)
        fullness = phase.from + (phase.to - phase.from) * eased
    }
}
