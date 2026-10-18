import SwiftUI

/// Icon, title and current value, for the option buttons on the home screen.
struct OptionLabel: View {
    var title: String
    var value: String
    var symbol: String

    var body: some View {
        HStack(spacing: Theme.Spacing.small) {
            Image(systemName: symbol)
                .font(.title3)
                .frame(width: 28)
                .foregroundStyle(.tint)
            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline)
                    .bold()
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, Theme.Spacing.medium)
        .padding(.vertical, Theme.Spacing.small)
        .frame(maxWidth: .infinity, minHeight: 56)
        .contentShape(.rect)
    }
}
