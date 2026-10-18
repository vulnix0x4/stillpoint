import Foundation

/// Pink noise via Paul Kellet's refined filter: roughly -3 dB per octave.
nonisolated struct PinkNoise {
    private var b0: Float = 0, b1: Float = 0, b2: Float = 0, b3: Float = 0
    private var b4: Float = 0, b5: Float = 0, b6: Float = 0

    mutating func next(_ white: Float) -> Float {
        b0 = 0.99886 * b0 + white * 0.0555179
        b1 = 0.99332 * b1 + white * 0.0750759
        b2 = 0.96900 * b2 + white * 0.1538520
        b3 = 0.86650 * b3 + white * 0.3104856
        b4 = 0.55000 * b4 + white * 0.5329522
        b5 = -0.7616 * b5 - white * 0.0168980
        let pink = b0 + b1 + b2 + b3 + b4 + b5 + b6 + white * 0.5362
        b6 = white * 0.115926
        return pink * 0.11
    }
}

/// Brown (red) noise: leaky-integrated white noise, about -6 dB per octave.
nonisolated struct BrownNoise {
    private var last: Float = 0

    mutating func next(_ white: Float) -> Float {
        last = (last + 0.02 * white) / 1.02
        return last * 3.5
    }
}
