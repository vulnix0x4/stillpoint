import Foundation

/// One square in the focus heatmap.
nonisolated struct HeatmapCell: Identifiable, Equatable, Sendable {
    var date: Date
    var minutes: Double
    /// Days after today are laid out but not drawn.
    var isFuture: Bool

    var id: Date { date }

    /// Intensity bucket from 0 (nothing) to 4 (a big day).
    var level: Int {
        switch minutes {
        case ..<1: 0
        case ..<30: 1
        case ..<75: 2
        case ..<150: 3
        default: 4
        }
    }
}
