import Foundation
import Synchronization

/// A synthesised singing bowl. Its partials follow the inharmonic ratios of a struck bowl,
/// with near-unison pairs that beat slowly against each other, giving the characteristic shimmer.
nonisolated final class BellVoice: @unchecked Sendable {
    private struct Partial {
        var phase: Float = 0
        var increment: Float
        var peak: Float
        var amplitude: Float = 0
        var decay: Float
        var gainLeft: Float
        var gainRight: Float
    }

    private let sampleRate: Float
    private let strikes = Atomic<Int>(0)
    private let strength = AtomicFloat(1)
    private var handledStrikes = 0
    private var attackSamples = 0
    private let attackLength: Int
    private let partials: UnsafeMutableBufferPointer<Partial>

    init(sampleRate: Float) {
        self.sampleRate = sampleRate
        attackLength = Int(0.004 * sampleRate)
        let fundamental: Float = 233
        let shape: [(ratio: Float, peak: Float, seconds: Float, pan: Float)] = [
            (1.000, 0.42, 6.0, 0.45),
            (1.004, 0.30, 5.2, 0.55),
            (2.740, 0.20, 3.4, 0.40),
            (2.752, 0.11, 3.0, 0.62),
            (5.170, 0.08, 1.7, 0.50),
            (8.480, 0.04, 0.9, 0.48),
        ]
        let built = shape.map { item in
            Partial(
                increment: 2 * .pi * fundamental * item.ratio / sampleRate,
                peak: item.peak,
                decay: exp(-1 / (item.seconds * sampleRate)),
                gainLeft: (1 - item.pan).squareRoot(),
                gainRight: item.pan.squareRoot()
            )
        }
        partials = .allocate(capacity: built.count)
        _ = partials.initialize(from: built)
    }

    deinit {
        partials.deallocate()
    }

    /// Strikes the bowl. Safe to call from any thread.
    func ring(strength value: Float) {
        strength.set(value)
        // Releasing pairs with the render thread's acquiring load, so the new strength is
        // guaranteed to be visible alongside the new strike.
        strikes.add(1, ordering: .releasing)
    }

    /// Adds the bowl's sound on top of whatever is already in the buffers.
    func render(addingTo left: UnsafeMutablePointer<Float>, _ right: UnsafeMutablePointer<Float>, frames: Int) {
        let pending = strikes.load(ordering: .acquiring)
        if pending != handledStrikes {
            handledStrikes = pending
            let loudness = strength.value
            for index in 0..<partials.count {
                partials[index].amplitude = partials[index].peak * loudness
                partials[index].phase = 0
            }
            attackSamples = 0
        }

        guard partials[0].amplitude > 0.000_1 else { return }

        for i in 0..<frames {
            let attack = attackSamples < attackLength ? Float(attackSamples) / Float(attackLength) : 1
            attackSamples += 1
            var sampleLeft: Float = 0
            var sampleRight: Float = 0
            for index in 0..<partials.count {
                let value = sin(partials[index].phase) * partials[index].amplitude * attack
                sampleLeft += value * partials[index].gainLeft
                sampleRight += value * partials[index].gainRight
                partials[index].phase += partials[index].increment
                if partials[index].phase > 2 * .pi { partials[index].phase -= 2 * .pi }
                partials[index].amplitude *= partials[index].decay
            }
            left[i] += sampleLeft
            right[i] += sampleRight
        }
    }
}
