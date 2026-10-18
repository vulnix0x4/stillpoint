import SwiftUI

/// A calendar of the last few months, one square per day, brighter for more focus.
struct FocusHeatmap: View {
    var cells: [[HeatmapCell]]
    var palette: OrbPalette

    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor

    private static let spacing: Double = 3

    var body: some View {
        let activeDays = cells.joined().count { $0.minutes >= 1 && !$0.isFuture }
        let totalDays = cells.joined().count { !$0.isFuture }

        VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
            VStack(alignment: .leading, spacing: Theme.Spacing.hairline) {
                Text("Consistency")
                    .font(.sectionTitle)
                Text("Focused on \(activeDays) of the last \(totalDays) days")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(alignment: .top, spacing: Self.spacing) {
                ForEach(cells.indices, id: \.self) { column in
                    VStack(spacing: Self.spacing) {
                        ForEach(cells[column]) { cell in
                            RoundedRectangle(cornerRadius: Theme.Radius.cell)
                                .fill(color(for: cell))
                                .overlay {
                                    if differentiateWithoutColor, cell.level >= 3 {
                                        Circle()
                                            .fill(Theme.ink.opacity(0.6))
                                            .padding(4)
                                    }
                                }
                                .aspectRatio(1, contentMode: .fit)
                                .opacity(cell.isFuture ? 0 : 1)
                        }
                    }
                }
            }

            HStack(spacing: Theme.Spacing.tight) {
                Text("Less")
                ForEach(0..<5) { level in
                    RoundedRectangle(cornerRadius: Theme.Radius.cell)
                        .fill(color(forLevel: level))
                        .frame(width: 12, height: 12)
                }
                Text("More")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Consistency heatmap")
        .accessibilityValue("Focused on \(activeDays) of the last \(totalDays) days")
    }

    private func color(for cell: HeatmapCell) -> Color {
        color(forLevel: cell.level)
    }

    private func color(forLevel level: Int) -> Color {
        switch level {
        case 0: Color.white.opacity(0.06)
        case 1: palette.rim.opacity(0.55)
        case 2: palette.rim.mix(with: palette.mid, by: 0.6)
        case 3: palette.mid
        default: palette.mid.mix(with: palette.core, by: 0.6)
        }
    }
}
