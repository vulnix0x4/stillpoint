import AVFoundation

/// Mixes every soundscape layer, plus the bell, on the real-time audio thread.
///
/// The main thread only ever writes atomic targets; all smoothing happens per sample here, so
/// level changes and fades are click-free.
nonisolated final class SoundscapeRenderer: @unchecked Sendable {
    private static let chunkSize = 1_024

    let sampleRate: Float
    let binaural: BinauralGenerator
    let bell: BellVoice
    /// Overall soundscape level (not applied to the bell).
    let master = AtomicFloat(0)

    private let layers: [any SignalGenerator]
    private let targets: [AtomicFloat]
    private let gains: UnsafeMutableBufferPointer<Float>
    private let scratchLeft: UnsafeMutablePointer<Float>
    private let scratchRight: UnsafeMutablePointer<Float>
    private let layerSmoothing: Float
    private let masterSmoothing: Float
    private var masterGain: Float = 0

    init(sampleRate: Float) {
        self.sampleRate = sampleRate
        let binaural = BinauralGenerator(sampleRate: sampleRate)
        self.binaural = binaural
        bell = BellVoice(sampleRate: sampleRate)
        layers = SoundLayer.allCases.map { layer -> any SignalGenerator in
            switch layer {
            case .rain: RainGenerator(sampleRate: sampleRate)
            case .ocean: OceanGenerator(sampleRate: sampleRate)
            case .hearth: HearthGenerator(sampleRate: sampleRate)
            case .brown: BrownNoiseGenerator(sampleRate: sampleRate)
            case .drone: DroneGenerator(sampleRate: sampleRate)
            case .binaural: binaural
            }
        }
        targets = SoundLayer.allCases.map { _ in AtomicFloat(0) }
        gains = .allocate(capacity: SoundLayer.allCases.count)
        gains.initialize(repeating: 0)
        scratchLeft = .allocate(capacity: Self.chunkSize)
        scratchRight = .allocate(capacity: Self.chunkSize)
        layerSmoothing = 1 - exp(-1 / (0.12 * sampleRate))
        masterSmoothing = 1 - exp(-1 / (0.6 * sampleRate))
    }

    deinit {
        gains.deallocate()
        scratchLeft.deallocate()
        scratchRight.deallocate()
    }

    func setTarget(_ gain: Float, for layer: SoundLayer) {
        targets[layer.index].set(gain)
    }

    func render(frames: Int, left: UnsafeMutablePointer<Float>, right: UnsafeMutablePointer<Float>) {
        var offset = 0
        while offset < frames {
            let count = min(Self.chunkSize, frames - offset)
            let outLeft = left + offset
            let outRight = right + offset
            outLeft.update(repeating: 0, count: count)
            outRight.update(repeating: 0, count: count)

            for index in layers.indices {
                let target = targets[index].value
                var gain = gains[index]
                // Silent layers aren't rendered at all.
                if target < 0.000_01, gain < 0.000_1 {
                    gains[index] = 0
                    continue
                }
                layers[index].render(left: scratchLeft, right: scratchRight, frames: count)
                for i in 0..<count {
                    gain += (target - gain) * layerSmoothing
                    outLeft[i] += scratchLeft[i] * gain
                    outRight[i] += scratchRight[i] * gain
                }
                gains[index] = gain
            }

            let masterTarget = master.value
            for i in 0..<count {
                masterGain += (masterTarget - masterGain) * masterSmoothing
                outLeft[i] = tanh(outLeft[i] * masterGain)
                outRight[i] = tanh(outRight[i] * masterGain)
            }

            bell.render(addingTo: outLeft, outRight, frames: count)
            offset += count
        }
    }

    /// Builds the source node that pulls audio from `renderer`. Kept nonisolated so the render
    /// block is never treated as main-actor code.
    static func makeSourceNode(for renderer: SoundscapeRenderer, format: AVAudioFormat) -> AVAudioSourceNode {
        AVAudioSourceNode(format: format) { _, _, frameCount, audioBufferList in
            let buffers = UnsafeMutableAudioBufferListPointer(audioBufferList)
            guard buffers.count >= 2,
                  let left = buffers[0].mData?.assumingMemoryBound(to: Float.self),
                  let right = buffers[1].mData?.assumingMemoryBound(to: Float.self)
            else { return noErr }
            renderer.render(frames: Int(frameCount), left: left, right: right)
            return noErr
        }
    }
}
