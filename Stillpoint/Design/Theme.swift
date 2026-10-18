import SwiftUI

/// Shared design constants so every screen feels like part of the same quiet room.
enum Theme {
    /// The near-black, faintly blue canvas behind everything.
    static let canvas = Color(red: 0.035, green: 0.039, blue: 0.063)
    /// Dark ink for text that sits on the bright core of the orb.
    static let ink = Color(red: 0.08, green: 0.06, blue: 0.09)
    /// Hairline strokes on cards.
    static let hairline = Color.white.opacity(0.08)
    /// Card fill on the canvas.
    static let surface = Color.white.opacity(0.045)

    enum Spacing {
        static let hairline: Double = 2
        static let tight: Double = 6
        static let small: Double = 10
        static let medium: Double = 16
        static let large: Double = 24
        static let xLarge: Double = 36
    }

    enum Radius {
        static let card: Double = 26
        static let control: Double = 20
        static let cell: Double = 3
    }

    enum Motion {
        static let settle = Animation.smooth(duration: 0.7)
        static let quick = Animation.snappy(duration: 0.3)
        static let reveal = Animation.easeOut(duration: 0.45)
        static let fadeAway = Animation.easeInOut(duration: 1.4)
        static let stageChange = Animation.smooth(duration: 0.9)
    }
}

extension Font {
    /// Large literary headings.
    static let display = Font.system(.largeTitle, design: .serif)
    /// The intention, wherever it appears.
    static let intention = Font.system(.title2, design: .serif)
    static let sectionTitle = Font.system(.title3, design: .serif)
}
