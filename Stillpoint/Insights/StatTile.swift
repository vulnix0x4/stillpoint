import SwiftUI

/// A single headline statistic.
struct StatTile: View {
    var title: String
    var value: String
    var symbol: String
    var footnote: String?

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.tight) {
            Label(title, systemImage: symbol)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(.title, design: .rounded))
                .bold()
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(footnote ?? " ")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .cardSurface()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue([value, footnote].compactMap(\.self).joined(separator: ", "))
    }
}
