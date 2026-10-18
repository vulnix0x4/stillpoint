import Foundation

/// A tiny, allocation-free xorshift generator, safe to use on the real-time audio thread.
nonisolated struct RandomSource {
    private var state: UInt32

    init(seed: UInt32) {
        state = seed == 0 ? 0x9E37_79B9 : seed
    }

    mutating func next() -> UInt32 {
        state ^= state << 13
        state ^= state >> 17
        state ^= state << 5
        return state
    }

    /// Uniform value in 0..<1.
    mutating func unit() -> Float {
        Float(next() >> 8) * (1 / 16_777_216)
    }

    /// Uniform value in -1..<1.
    mutating func bipolar() -> Float {
        unit() * 2 - 1
    }

    mutating func range(_ lower: Float, _ upper: Float) -> Float {
        lower + (upper - lower) * unit()
    }

    mutating func chance(_ probability: Float) -> Bool {
        unit() < probability
    }
}
