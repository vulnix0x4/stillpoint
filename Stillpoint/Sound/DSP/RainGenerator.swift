import Foundation

/// Rainfall: a filtered noise bed for the distant patter, plus individually synthesised
/// droplets. Each droplet is a short, rising sine "plip", which is how a bubble trapped by a
/// raindrop actually sounds.
nonisolated final class RainGenerator: SignalGenerator {
    private struct Drop {
        var isActive = false
        var phase: Float = 0
        var increment: Float = 0
        var chirp: Float = 1
        var amplitude: Float = 0
        var decay: Float = 0
        var gainLeft: Float = 0
        var gainRight: Float = 0
    }

    private let sampleRate: Float
    private var random = RandomSource(seed: 0xA11CE)
    private var pinkLeft = PinkNoise()
    private var pinkRight = PinkNoise()
    private var highLeft: OnePoleHighpass
    private var highRight: OnePoleHighpass
    private var lowLeft: OnePoleLowpass
    private var lowRight: OnePoleLowpass
    private var intensity = RandomWalk(lower: 0.72, upper: 1, rate: 0.000_02)
    private let drops: UnsafeMutableBufferPointer<Drop>
    private let dropChance: Float
    /// Highest pitch a drop may chirp up to: about 8 kHz.
    private let maxIncrement: Float

    init(sampleRate: Float) {
        self.sampleRate = sampleRate
        highLeft = OnePoleHighpass(cutoff: 420, sampleRate: sampleRate)
        highRight = OnePoleHighpass(cutoff: 420, sampleRate: sampleRate)
        lowLeft = OnePoleLowpass(cutoff: 6_800, sampleRate: sampleRate)
        lowRight = OnePoleLowpass(cutoff: 6_800, sampleRate: sampleRate)
        drops = .allocate(capacity: 32)
        drops.initialize(repeating: Drop())
        dropChance = 70 / sampleRate
        maxIncrement = 2 * .pi * 8_000 / sampleRate
    }

    deinit {
        drops.deallocate()
    }

    func render(left: UnsafeMutablePointer<Float>, right: UnsafeMutablePointer<Float>, frames: Int) {
        for i in 0..<frames {
            let level = intensity.next(&random)
            var sampleLeft = lowLeft.process(highLeft.process(pinkLeft.next(random.bipolar()))) * 1.1 * level
            var sampleRight = lowRight.process(highRight.process(pinkRight.next(random.bipolar()))) * 1.1 * level

            if random.chance(dropChance * level) {
                spawnDrop()
            }

            for index in 0..<drops.count where drops[index].isActive {
                let value = sin(drops[index].phase) * drops[index].amplitude
                sampleLeft += value * drops[index].gainLeft
                sampleRight += value * drops[index].gainRight
                drops[index].phase += drops[index].increment
                if drops[index].phase > 2 * .pi { drops[index].phase -= 2 * .pi }
                // The bubble's pitch rises, but never toward Nyquist where it would alias.
                drops[index].increment = min(drops[index].increment * drops[index].chirp, maxIncrement)
                drops[index].amplitude *= drops[index].decay
                if drops[index].amplitude < 0.000_5 {
                    drops[index].isActive = false
                }
            }

            left[i] = sampleLeft
            right[i] = sampleRight
        }
    }

    private func spawnDrop() {
        guard let slot = drops.firstIndex(where: { !$0.isActive }) else { return }
        // Most drops are small and bright; a few are heavy drips from eaves and leaves.
        let isHeavy = random.chance(0.08)
        let frequency = isHeavy ? random.range(500, 1_100) : random.range(1_400, 4_400)
        let loudness = random.unit()
        let amplitude = isHeavy ? random.range(0.18, 0.42) : 0.025 + loudness * loudness * loudness * 0.32
        let timeConstant = isHeavy ? random.range(0.012, 0.03) : random.range(0.003, 0.014)
        let pan = random.unit()

        drops[slot] = Drop(
            isActive: true,
            phase: 0,
            increment: 2 * .pi * frequency / sampleRate,
            chirp: 1 + random.range(0.000_1, 0.000_45),
            amplitude: amplitude,
            decay: exp(-1 / (timeConstant * sampleRate)),
            gainLeft: (1 - pan).squareRoot(),
            gainRight: pan.squareRoot()
        )
    }
}
