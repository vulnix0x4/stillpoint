import Foundation

/// A slow, warm chord (A major add 9) whose notes swell and recede independently, so the
/// harmony never quite repeats. Each note is a pair of slightly detuned oscillators reading a
/// soft, organ-like wavetable.
nonisolated final class DroneGenerator: SignalGenerator {
    private struct Voice {
        var phase: Float
        var increment: Float
        var lfoPhase: Float
        var lfoIncrement: Float
        var gain: Float
        var gainLeft: Float
        var gainRight: Float
        var level: Float = 0
    }

    private static let tableSize = 2_048
    private static let controlInterval = 64
    private static let notes: [(frequency: Float, gain: Float)] = [
        (110.00, 0.9), (164.81, 0.65), (220.00, 0.55),
        (246.94, 0.32), (277.18, 0.38), (329.63, 0.28),
    ]

    private let table: UnsafeMutableBufferPointer<Float>
    private let voices: UnsafeMutableBufferPointer<Voice>
    private var lowLeft: OnePoleLowpass
    private var lowRight: OnePoleLowpass
    private var controlCounter = 0

    init(sampleRate: Float) {
        table = .allocate(capacity: Self.tableSize + 1)
        for index in 0...Self.tableSize {
            let x = 2 * Float.pi * Float(index) / Float(Self.tableSize)
            table[index] = (sin(x) + 0.3 * sin(2 * x) + 0.12 * sin(3 * x) + 0.05 * sin(4 * x)) / 1.3
        }

        var random = RandomSource(seed: 0xD_2013)
        var built: [Voice] = []
        for (noteIndex, note) in Self.notes.enumerated() {
            for detuneCents: Float in [-4, 4] {
                let frequency = note.frequency * pow(2, detuneCents / 1_200)
                let pan = 0.5 + (Float(noteIndex % 2 == 0 ? -1 : 1) * 0.12) + detuneCents / 40
                built.append(Voice(
                    phase: random.unit(),
                    increment: frequency / sampleRate,
                    lfoPhase: random.unit() * 2 * .pi,
                    lfoIncrement: 2 * .pi * random.range(0.015, 0.06) / sampleRate * Float(Self.controlInterval),
                    gain: note.gain,
                    gainLeft: (1 - pan).squareRoot(),
                    gainRight: pan.squareRoot()
                ))
            }
        }
        voices = .allocate(capacity: built.count)
        _ = voices.initialize(from: built)

        lowLeft = OnePoleLowpass(cutoff: 1_500, sampleRate: sampleRate)
        lowRight = OnePoleLowpass(cutoff: 1_500, sampleRate: sampleRate)
    }

    deinit {
        table.deallocate()
        voices.deallocate()
    }

    func render(left: UnsafeMutablePointer<Float>, right: UnsafeMutablePointer<Float>, frames: Int) {
        let size = Float(Self.tableSize)
        for i in 0..<frames {
            if controlCounter == 0 {
                for index in 0..<voices.count {
                    voices[index].lfoPhase += voices[index].lfoIncrement
                    if voices[index].lfoPhase > 2 * .pi { voices[index].lfoPhase -= 2 * .pi }
                    voices[index].level = voices[index].gain * (0.3 + 0.7 * (0.5 + 0.5 * sin(voices[index].lfoPhase)))
                }
            }
            controlCounter = (controlCounter + 1) % Self.controlInterval

            var sampleLeft: Float = 0
            var sampleRight: Float = 0
            for index in 0..<voices.count {
                let position = voices[index].phase * size
                let integer = Int(position)
                let fraction = position - Float(integer)
                let value = table[integer] + (table[integer + 1] - table[integer]) * fraction
                let scaled = value * voices[index].level
                sampleLeft += scaled * voices[index].gainLeft
                sampleRight += scaled * voices[index].gainRight
                voices[index].phase += voices[index].increment
                if voices[index].phase >= 1 { voices[index].phase -= 1 }
            }

            left[i] = lowLeft.process(sampleLeft) * 0.21
            right[i] = lowRight.process(sampleRight) * 0.21
        }
    }
}
