import CoreHaptics
import os

/// Plays a continuous haptic that swells with the inhale and ebbs with the exhale, so you can
/// follow the breath with your eyes closed.
final class BreathHaptics {
    private var engine: CHHapticEngine?
    private var player: (any CHHapticPatternPlayer)?
    private let logger = Logger(subsystem: "dev.stillpoint", category: "haptics")

    init() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            let engine = try CHHapticEngine()
            engine.isAutoShutdownEnabled = true
            engine.resetHandler = { [weak engine] in
                try? engine?.start()
            }
            self.engine = engine
        } catch {
            logger.error("Haptics unavailable: \(error.localizedDescription)")
        }
    }

    func play(_ phase: BreathPhase) {
        guard let engine else { return }
        do {
            try engine.start()
            try player?.stop(atTime: CHHapticTimeImmediate)
            let pattern = try Self.pattern(for: phase)
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
            self.player = player
        } catch {
            logger.error("Couldn't play breath haptic: \(error.localizedDescription)")
        }
    }

    func stop() {
        try? player?.stop(atTime: CHHapticTimeImmediate)
        player = nil
        engine?.stop()
    }

    private static func pattern(for phase: BreathPhase) throws -> CHHapticPattern {
        switch phase.kind {
        case .hold, .rest:
            // A single soft tap marks the turn of the breath.
            let tap = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.35),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2),
                ],
                relativeTime: 0
            )
            return try CHHapticPattern(events: [tap], parameters: [])

        case .inhale, .topUp, .exhale:
            let rising = phase.kind != .exhale
            let start: Float = rising ? 0.08 : 0.55
            let end: Float = rising ? 0.55 : 0.04
            let duration = phase.duration
            let event = CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 1),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.1),
                ],
                relativeTime: 0,
                duration: duration
            )
            let curve = CHHapticParameterCurve(
                parameterID: .hapticIntensityControl,
                controlPoints: [
                    CHHapticParameterCurve.ControlPoint(relativeTime: 0, value: start),
                    CHHapticParameterCurve.ControlPoint(relativeTime: duration, value: end),
                ],
                relativeTime: 0
            )
            return try CHHapticPattern(events: [event], parameterCurves: [curve])
        }
    }
}
