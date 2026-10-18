import Foundation

/// Waves on a shore. Two independent swells with irregular periods sweep a low-pass filter
/// over pink noise: the filter opens as a wave builds and crashes, then closes as the wash
/// drains away. A constant low rumble sits underneath.
nonisolated final class OceanGenerator: SignalGenerator {
    private struct Swell {
        var phase: Float
        var increment: Float
        var pan: Float
        var strength: Float
    }

    private let sampleRate: Float
    private var random = RandomSource(seed: 0x0CEA_4)
    private var pinkLeft = PinkNoise()
    private var pinkRight = PinkNoise()
    private var rumble = BrownNoise()
    private var rumbleFilter: OnePoleLowpass
    private var filterLeft: StateVariableFilter
    private var filterRight: StateVariableFilter
    private var swells: [Swell]
    private var controlCounter = 0
    private var envelopeLeft: Float = 0
    private var envelopeRight: Float = 0
    private static let controlInterval = 32

    init(sampleRate: Float) {
        self.sampleRate = sampleRate
        rumbleFilter = OnePoleLowpass(cutoff: 140, sampleRate: sampleRate)
        filterLeft = StateVariableFilter(cutoff: 400, resonance: 0.6, sampleRate: sampleRate)
        filterRight = StateVariableFilter(cutoff: 400, resonance: 0.6, sampleRate: sampleRate)
        swells = []
        swells = [makeSwell(startingAt: 0.1), makeSwell(startingAt: 0.62)]
    }

    func render(left: UnsafeMutablePointer<Float>, right: UnsafeMutablePointer<Float>, frames: Int) {
        for i in 0..<frames {
            if controlCounter == 0 {
                updateControl()
            }
            controlCounter = (controlCounter + 1) % Self.controlInterval

            let noiseLeft = pinkLeft.next(random.bipolar())
            let noiseRight = pinkRight.next(random.bipolar())
            let bodyLeft = filterLeft.process(noiseLeft).low
            let bodyRight = filterRight.process(noiseRight).low
            let base = rumbleFilter.process(rumble.next(random.bipolar())) * 0.9

            // Foam: brighter hiss that only appears near the crest of a wave.
            let foamLeft = noiseLeft * envelopeLeft * envelopeLeft * 0.16
            let foamRight = noiseRight * envelopeRight * envelopeRight * 0.16

            left[i] = (bodyLeft * (0.25 + 1.6 * envelopeLeft) + foamLeft + base) * 0.58
            right[i] = (bodyRight * (0.25 + 1.6 * envelopeRight) + foamRight + base) * 0.58
        }
    }

    private func updateControl() {
        var left: Float = 0
        var right: Float = 0
        for index in swells.indices {
            swells[index].phase += swells[index].increment * Float(Self.controlInterval)
            if swells[index].phase >= 1 {
                swells[index] = makeSwell(startingAt: swells[index].phase - 1)
            }
            let envelope = Self.envelope(swells[index].phase) * swells[index].strength
            let pan = swells[index].pan
            left += envelope * (1 - pan).squareRoot()
            right += envelope * pan.squareRoot()
        }
        envelopeLeft = min(1, left * 0.8)
        envelopeRight = min(1, right * 0.8)
        filterLeft.set(cutoff: 180 + 2_800 * pow(envelopeLeft, 1.4), resonance: 0.6, sampleRate: sampleRate)
        filterRight.set(cutoff: 180 + 2_800 * pow(envelopeRight, 1.4), resonance: 0.6, sampleRate: sampleRate)
    }

    private func makeSwell(startingAt phase: Float) -> Swell {
        let period = random.range(7, 12.5)
        return Swell(
            phase: phase,
            increment: 1 / (period * sampleRate),
            pan: random.range(0.2, 0.8),
            strength: random.range(0.55, 1)
        )
    }

    /// Slow build, crash, then a long draining wash. Zero at both ends so swells chain smoothly.
    private static func envelope(_ phase: Float) -> Float {
        let crest: Float = 0.38
        let rise = smoothstep(0, crest, phase)
        let wash = exp(-max(0, phase - crest) * 4.2)
        let fadeOut = 1 - smoothstep(0.85, 1, phase)
        return rise * wash * fadeOut
    }

    private static func smoothstep(_ edge0: Float, _ edge1: Float, _ x: Float) -> Float {
        let t = min(1, max(0, (x - edge0) / (edge1 - edge0)))
        return t * t * (3 - 2 * t)
    }
}
