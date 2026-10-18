import Foundation

/// Two pure tones a few hertz apart, one per ear. Only meaningful on headphones.
nonisolated final class BinauralGenerator: SignalGenerator {
    /// Difference between the ears, in hertz. Written from the main thread.
    let beatFrequency = AtomicFloat(10)

    private let sampleRate: Float
    private let carrier: Float = 196
    private var phaseLeft: Float = 0
    private var phaseRight: Float = 0

    init(sampleRate: Float) {
        self.sampleRate = sampleRate
    }

    func render(left: UnsafeMutablePointer<Float>, right: UnsafeMutablePointer<Float>, frames: Int) {
        let incrementLeft = carrier / sampleRate
        let incrementRight = (carrier + beatFrequency.value) / sampleRate
        for i in 0..<frames {
            left[i] = sin(2 * .pi * phaseLeft) * 0.15
            right[i] = sin(2 * .pi * phaseRight) * 0.15
            phaseLeft += incrementLeft
            phaseRight += incrementRight
            if phaseLeft >= 1 { phaseLeft -= 1 }
            if phaseRight >= 1 { phaseRight -= 1 }
        }
    }
}
