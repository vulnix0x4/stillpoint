import Foundation

/// The beat frequency for binaural tones. Named after the EEG bands they correspond to.
nonisolated enum BinauralBand: String, CaseIterable, Identifiable, Codable, Sendable {
    case theta
    case alpha
    case beta
    case gamma

    var id: String { rawValue }

    var frequency: Float {
        switch self {
        case .theta: 6
        case .alpha: 10
        case .beta: 16
        case .gamma: 40
        }
    }

    var title: String {
        switch self {
        case .theta: "Theta · 6 Hz"
        case .alpha: "Alpha · 10 Hz"
        case .beta: "Beta · 16 Hz"
        case .gamma: "Gamma · 40 Hz"
        }
    }

    var shortTitle: String {
        switch self {
        case .theta: "Theta"
        case .alpha: "Alpha"
        case .beta: "Beta"
        case .gamma: "Gamma"
        }
    }
}
