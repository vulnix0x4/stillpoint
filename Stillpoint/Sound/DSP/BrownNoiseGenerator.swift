import Foundation

/// Deep, even noise that masks speech and room sound without hiss.
nonisolated final class BrownNoiseGenerator: SignalGenerator {
    private var random = RandomSource(seed: 0xB10_3A)
    private var brownL = BrownNoise()
    private var brownR = BrownNoise()
    private var smoothL: OnePoleLowpass
    private var smoothR: OnePoleLowpass
    private static let level: Float = 0.55

    init(sampleRate: Float) {
        smoothL = OnePoleLowpass(cutoff: 2_400, sampleRate: sampleRate)
        smoothR = OnePoleLowpass(cutoff: 2_400, sampleRate: sampleRate)
    }

    func render(left: UnsafeMutablePointer<Float>, right: UnsafeMutablePointer<Float>, frames: Int) {
        for i in 0..<frames {
            left[i] = smoothL.process(brownL.next(random.bipolar())) * Self.level
            right[i] = smoothR.process(brownR.next(random.bipolar())) * Self.level
        }
    }
}
