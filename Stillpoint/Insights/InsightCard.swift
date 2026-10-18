import SwiftUI

/// One generated insight.
struct InsightCard: View {
    var insight: Insight

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.medium) {
            Image(systemName: insight.symbol)
                .font(.title3)
                .foregroundStyle(.tint)
                .frame(width: 32, height: 32)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: Theme.Spacing.hairline) {
                Text(insight.title)
                    .font(.headline)
                Text(insight.detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .cardSurface()
        .accessibilityElement(children: .combine)
    }
}
