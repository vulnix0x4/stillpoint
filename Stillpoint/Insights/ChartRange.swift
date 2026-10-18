import Foundation

enum ChartRange: String, CaseIterable, Identifiable {
    case week
    case month

    var id: String { rawValue }

    var title: String {
        switch self {
        case .week: "7 days"
        case .month: "30 days"
        }
    }

    var days: Int {
        switch self {
        case .week: 7
        case .month: 30
        }
    }
}
