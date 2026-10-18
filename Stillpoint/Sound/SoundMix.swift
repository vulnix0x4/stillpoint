import Foundation

/// A set of layer levels. Presets are named mixes; anything else is "Custom".
nonisolated struct SoundMix: Codable, Equatable, Identifiable, Sendable {
    static let customName = "Custom"

    var name: String
    /// Slider positions, 0...1, per layer. Missing layers are silent.
    var levels: [SoundLayer: Double]

    var id: String { name }

    func level(for layer: SoundLayer) -> Double {
        levels[layer] ?? 0
    }

    var isSilent: Bool {
        levels.values.allSatisfy { $0 < 0.01 }
    }

    var activeLayers: [SoundLayer] {
        SoundLayer.allCases.filter { level(for: $0) >= 0.01 }
    }

    /// Returns a copy with one layer changed, renamed to match a preset if it now equals one.
    func setting(_ level: Double, for layer: SoundLayer) -> SoundMix {
        var copy = self
        copy.levels[layer] = min(1, max(0, level))
        copy.name = SoundMix.presets.first { $0.hasSameLevels(as: copy) }?.name ?? Self.customName
        return copy
    }

    func hasSameLevels(as other: SoundMix) -> Bool {
        SoundLayer.allCases.allSatisfy { abs(level(for: $0) - other.level(for: $0)) < 0.01 }
    }

    static let silence = SoundMix(name: "Silence", levels: [:])

    static let presets: [SoundMix] = [
        silence,
        SoundMix(name: "Rainy Library", levels: [.rain: 0.75, .brown: 0.35]),
        SoundMix(name: "Storm Cabin", levels: [.rain: 0.85, .hearth: 0.6, .brown: 0.3]),
        SoundMix(name: "Shoreline", levels: [.ocean: 0.8, .drone: 0.3]),
        SoundMix(name: "Fireside", levels: [.hearth: 0.8, .drone: 0.25]),
        SoundMix(name: "Deep Work", levels: [.brown: 0.65, .drone: 0.2, .binaural: 0.35]),
    ]

    static let `default` = presets[1]
}
