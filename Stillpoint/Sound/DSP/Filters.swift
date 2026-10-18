import Foundation

/// A one-pole low-pass filter. Cheap and smooth, ideal for darkening noise.
nonisolated struct OnePoleLowpass {
    private var state: Float = 0
    private var coefficient: Float

    init(cutoff: Float, sampleRate: Float) {
        coefficient = OnePoleLowpass.coefficient(cutoff: cutoff, sampleRate: sampleRate)
    }

    static func coefficient(cutoff: Float, sampleRate: Float) -> Float {
        exp(-2 * .pi * cutoff / sampleRate)
    }

    mutating func setCutoff(_ cutoff: Float, sampleRate: Float) {
        coefficient = OnePoleLowpass.coefficient(cutoff: cutoff, sampleRate: sampleRate)
    }

    mutating func process(_ input: Float) -> Float {
        state = input + coefficient * (state - input)
        return state
    }
}

/// A one-pole high-pass filter built from the complementary low-pass.
nonisolated struct OnePoleHighpass {
    private var lowpass: OnePoleLowpass

    init(cutoff: Float, sampleRate: Float) {
        lowpass = OnePoleLowpass(cutoff: cutoff, sampleRate: sampleRate)
    }

    mutating func process(_ input: Float) -> Float {
        input - lowpass.process(input)
    }
}

/// A topology-preserving state-variable filter (Andrew Simper's formulation).
/// Stable under fast modulation, which matters for the ocean's sweeping waves.
nonisolated struct StateVariableFilter {
    struct Output {
        var low: Float
        var band: Float
        var high: Float
    }

    private var ic1: Float = 0
    private var ic2: Float = 0
    private var k: Float = 1
    private var a1: Float = 0
    private var a2: Float = 0
    private var a3: Float = 0

    init(cutoff: Float, resonance q: Float, sampleRate: Float) {
        set(cutoff: cutoff, resonance: q, sampleRate: sampleRate)
    }

    mutating func set(cutoff: Float, resonance q: Float, sampleRate: Float) {
        let safeCutoff = min(max(cutoff, 10), sampleRate * 0.45)
        let g = tan(.pi * safeCutoff / sampleRate)
        k = 1 / max(q, 0.1)
        a1 = 1 / (1 + g * (g + k))
        a2 = g * a1
        a3 = g * a2
    }

    mutating func process(_ input: Float) -> Output {
        let v3 = input - ic2
        let v1 = a1 * ic1 + a2 * v3
        let v2 = ic2 + a2 * ic1 + a3 * v3
        ic1 = 2 * v1 - ic1
        ic2 = 2 * v2 - ic2
        return Output(low: v2, band: v1, high: input - k * v1 - v2)
    }
}

/// A slowly wandering value in a range, for organic modulation.
nonisolated struct RandomWalk {
    private(set) var value: Float
    private var target: Float
    private let lower: Float
    private let upper: Float
    private let rate: Float

    /// - Parameter rate: Approximate fraction of the distance covered per sample.
    init(lower: Float, upper: Float, rate: Float) {
        self.lower = lower
        self.upper = upper
        self.rate = rate
        value = (lower + upper) / 2
        target = value
    }

    mutating func next(_ random: inout RandomSource) -> Float {
        if abs(target - value) < (upper - lower) * 0.02 {
            target = random.range(lower, upper)
        }
        value += (target - value) * rate
        return value
    }
}
