import Foundation

/// One synthesised ingredient of a soundscape.
nonisolated enum SoundLayer: String, CaseIterable, Identifiable, Codable, CodingKeyRepresentable, Sendable {
    case rain
    case ocean
    case hearth
    case brown
    case drone
    case binaural

    var id: String { rawValue }

    var title: String {
        switch self {
        case .rain: "Rain"
        case .ocean: "Shoreline"
        case .hearth: "Hearth"
        case .brown: "Brown noise"
        case .drone: "Warm drone"
        case .binaural: "Binaural tones"
        }
    }

    var detail: String {
        switch self {
        case .rain: "Soft rainfall with drips from the eaves"
        case .ocean: "Slow waves arriving and draining away"
        case .hearth: "A low fire that crackles now and then"
        case .brown: "Deep, even noise that masks voices"
        case .drone: "A slow chord that never quite repeats"
        case .binaural: "Two tones, one per ear. Needs headphones"
        }
    }

    var symbol: String {
        switch self {
        case .rain: "cloud.rain"
        case .ocean: "water.waves"
        case .hearth: "flame"
        case .brown: "waveform"
        case .drone: "music.note"
        case .binaural: "headphones"
        }
    }

    /// Position in the renderer's layer array.
    var index: Int {
        Self.allCases.firstIndex(of: self) ?? 0
    }
}
