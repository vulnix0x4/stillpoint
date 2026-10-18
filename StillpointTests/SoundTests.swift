import Foundation
import Testing
@testable import Stillpoint

struct SoundTests {
    @Test func adjustingALayerMakesTheMixCustom() {
        let mix = SoundMix.default.setting(0.1, for: .ocean)
        #expect(mix.name == SoundMix.customName)
        #expect(mix.level(for: .ocean) == 0.1)
    }

    @Test func matchingAPresetRestoresItsName() {
        let rainy = SoundMix.presets[1]
        let custom = rainy.setting(0.2, for: .rain)
        let back = custom.setting(rainy.level(for: .rain), for: .rain)
        #expect(back.name == rainy.name)
    }

    @Test func silenceIsSilent() {
        #expect(SoundMix.silence.isSilent)
        #expect(!SoundMix.default.isSilent)
        #expect(SoundMix.silence.activeLayers.isEmpty)
    }

    @Test func mixSurvivesEncoding() throws {
        let data = try JSONEncoder().encode(SoundMix.presets[2])
        let decoded = try JSONDecoder().decode(SoundMix.self, from: data)
        #expect(decoded == SoundMix.presets[2])
    }

    /// Renders a few seconds of every layer and checks the output is finite, audible and
    /// never clips, so a DSP mistake can't reach anyone's ears.
    @Test(arguments: SoundLayer.allCases)
    func layersRenderCleanAudio(layer: SoundLayer) {
        let sampleRate: Float = 48_000
        let renderer = SoundscapeRenderer(sampleRate: sampleRate)
        renderer.setTarget(1, for: layer)
        renderer.master.set(1)

        let frames = 512
        let left = UnsafeMutablePointer<Float>.allocate(capacity: frames)
        let right = UnsafeMutablePointer<Float>.allocate(capacity: frames)
        defer {
            left.deallocate()
            right.deallocate()
        }

        var sumSquares: Double = 0
        var peak: Float = 0
        var count = 0
        var nonFinite = 0
        let blocks = Int(sampleRate) * 4 / frames
        for block in 0..<blocks {
            renderer.render(frames: frames, left: left, right: right)
            // Skip the first second while gains ramp up.
            guard block > Int(sampleRate) / frames else { continue }
            for i in 0..<frames {
                if !left[i].isFinite || !right[i].isFinite { nonFinite += 1 }
                sumSquares += Double(left[i] * left[i] + right[i] * right[i])
                peak = max(peak, abs(left[i]), abs(right[i]))
                count += 2
            }
        }
        let rms = (sumSquares / Double(count)).squareRoot()
        print("\(layer.rawValue): rms \(rms), peak \(peak)")
        #expect(nonFinite == 0)
        #expect(rms > 0.02, "\(layer.title) is too quiet: \(rms)")
        #expect(rms < 0.35, "\(layer.title) is too loud: \(rms)")
        #expect(peak < 1)
    }

    @Test func bellRingsWithoutTheSoundscape() {
        let renderer = SoundscapeRenderer(sampleRate: 48_000)
        renderer.bell.ring(strength: 1)
        let frames = 4_800
        let left = UnsafeMutablePointer<Float>.allocate(capacity: frames)
        let right = UnsafeMutablePointer<Float>.allocate(capacity: frames)
        defer {
            left.deallocate()
            right.deallocate()
        }
        renderer.render(frames: frames, left: left, right: right)
        let peak = (0..<frames).map { abs(left[$0]) }.max() ?? 0
        #expect(peak > 0.1)
        #expect(peak < 1.2)
    }
}
