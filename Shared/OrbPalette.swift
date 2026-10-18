import SwiftUI

/// The colour worlds the orb (and the rest of the app) can live in.
nonisolated enum OrbPalette: String, CaseIterable, Identifiable, Codable, Sendable {
    case ember
    case tide
    case moss
    case aurora

    var id: String { rawValue }

    var title: String {
        switch self {
        case .ember: "Ember"
        case .tide: "Tide"
        case .moss: "Moss"
        case .aurora: "Aurora"
        }
    }

    /// The brightest, hottest colour at the centre of the orb.
    var core: Color {
        switch self {
        case .ember: Color(red: 1.00, green: 0.88, blue: 0.68)
        case .tide: Color(red: 0.86, green: 1.00, blue: 0.97)
        case .moss: Color(red: 0.95, green: 1.00, blue: 0.80)
        case .aurora: Color(red: 1.00, green: 0.90, blue: 0.98)
        }
    }

    /// The body colour of the orb.
    var mid: Color {
        switch self {
        case .ember: Color(red: 0.98, green: 0.46, blue: 0.33)
        case .tide: Color(red: 0.18, green: 0.76, blue: 0.84)
        case .moss: Color(red: 0.47, green: 0.82, blue: 0.43)
        case .aurora: Color(red: 0.82, green: 0.42, blue: 0.94)
        }
    }

    /// The cool outer edge and glow.
    var rim: Color {
        switch self {
        case .ember: Color(red: 0.42, green: 0.22, blue: 0.76)
        case .tide: Color(red: 0.12, green: 0.26, blue: 0.72)
        case .moss: Color(red: 0.05, green: 0.36, blue: 0.40)
        case .aurora: Color(red: 0.22, green: 0.52, blue: 0.96)
        }
    }

    /// Interface tint: readable on the dark canvas.
    var accent: Color {
        switch self {
        case .ember: Color(red: 1.00, green: 0.62, blue: 0.45)
        case .tide: Color(red: 0.40, green: 0.86, blue: 0.92)
        case .moss: Color(red: 0.64, green: 0.89, blue: 0.54)
        case .aurora: Color(red: 0.80, green: 0.60, blue: 1.00)
        }
    }

    static func named(_ rawValue: String?) -> OrbPalette {
        rawValue.flatMap(OrbPalette.init(rawValue:)) ?? .ember
    }
}
