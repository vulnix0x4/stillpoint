import Foundation

/// A wood fire: a flickering low roar plus crackles and the occasional pop. Crackles arrive
/// in bursts, the way resin and moisture in real wood give way.
nonisolated final class HearthGenerator: SignalGenerator {
    private struct Crackle {
        var isActive = false
        var remaining = 0
        var amplitude: Float = 0
        var decay: Float = 0
        var filter = StateVariableFilter(cutoff: 2_000, resonance: 1, sampleRate: 48_000)
        var gainLeft: Float = 0
        var gainRight: Float = 0
    }

    private let sampleRate: Float
    private var random = RandomSource(seed: 0xF1_4E)
    private var brownLeft = BrownNoise()
    private var brownRight = BrownNoise()
    private var pink = PinkNoise()
    private var rumbleLeft: OnePoleLowpass
    private var rumbleRight: OnePoleLowpass
    private var roarFilter: StateVariableFilter
    private var flicker = RandomWalk(lower: 0.5, upper: 1, rate: 0.000_06)
    private let crackles: UnsafeMutableBufferPointer<Crackle>
    private var burstSamplesLeft = 0
    private let baseChance: Float
    private let burstChance: Float
    private let burstStartChance: Float

    init(sampleRate: Float) {
        self.sampleRate = sampleRate
        rumbleLeft = OnePoleLowpass(cutoff: 170, sampleRate: sampleRate)
        rumbleRight = OnePoleLowpass(cutoff: 170, sampleRate: sampleRate)
        roarFilter = StateVariableFilter(cutoff: 650, resonance: 0.7, sampleRate: sampleRate)
        crackles = .allocate(capacity: 24)
        crackles.initialize(repeating: Crackle())
        baseChance = 6 / sampleRate
        burstChance = 48 / sampleRate
        burstStartChance = 0.45 / sampleRate
    }

    deinit {
        crackles.deallocate()
    }

    func render(left: UnsafeMutablePointer<Float>, right: UnsafeMutablePointer<Float>, frames: Int) {
        for i in 0..<frames {
            let glow = flicker.next(&random)
            let roar = roarFilter.process(pink.next(random.bipolar())).band * 0.2 * glow
            var sampleLeft = rumbleLeft.process(brownLeft.next(random.bipolar())) * 1.1 * glow + roar
            var sampleRight = rumbleRight.process(brownRight.next(random.bipolar())) * 1.1 * glow + roar

            if burstSamplesLeft > 0 {
                burstSamplesLeft -= 1
            } else if random.chance(burstStartChance) {
                burstSamplesLeft = Int(random.range(0.08, 0.35) * sampleRate)
            }
            if random.chance(burstSamplesLeft > 0 ? burstChance : baseChance) {
                spawnCrackle()
            }

            for index in 0..<crackles.count where crackles[index].isActive {
                let excitation = random.bipolar() * crackles[index].amplitude
                let value = crackles[index].filter.process(excitation).band
                sampleLeft += value * crackles[index].gainLeft
                sampleRight += value * crackles[index].gainRight
                crackles[index].amplitude *= crackles[index].decay
                crackles[index].remaining -= 1
                if crackles[index].remaining <= 0 {
                    crackles[index].isActive = false
                }
            }

            left[i] = sampleLeft
            right[i] = sampleRight
        }
    }

    private func spawnCrackle() {
        guard let slot = crackles.firstIndex(where: { !$0.isActive }) else { return }
        let isPop = random.chance(0.06)
        let center = isPop ? random.range(450, 1_100) : random.range(1_500, 6_500)
        let timeConstant = isPop ? random.range(0.004, 0.009) : random.range(0.000_4, 0.002_5)
        let loudness = random.unit()
        let pan = random.range(0.15, 0.85)

        crackles[slot] = Crackle(
            isActive: true,
            remaining: Int(timeConstant * 6 * sampleRate),
            amplitude: isPop ? random.range(0.7, 1.3) : 0.15 + loudness * loudness * 0.8,
            decay: exp(-1 / (timeConstant * sampleRate)),
            filter: StateVariableFilter(cutoff: center, resonance: isPop ? 2.5 : 1.4, sampleRate: sampleRate),
            gainLeft: (1 - pan).squareRoot(),
            gainRight: pan.squareRoot()
        )
    }
}
