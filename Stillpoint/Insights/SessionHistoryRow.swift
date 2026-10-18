import SwiftUI

/// A compact summary of a past session.
struct SessionHistoryRow: View {
    var session: FocusSession

    var body: some View {
        HStack(spacing: Theme.Spacing.medium) {
            VStack(alignment: .leading, spacing: Theme.Spacing.hairline) {
                Text(session.intention.isEmpty ? "Untitled session" : session.intention)
                    .font(.body)
                    .lineLimit(1)
                Text(session.startDate, format: .dateTime.weekday(.abbreviated).day().month(.abbreviated).hour().minute())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: Theme.Spacing.small)
            if let outcome = session.outcome {
                Image(systemName: outcome.symbol)
                    .foregroundStyle(.tint)
                    .accessibilityLabel(outcome.title)
            }
            Text(TimeText.short(session.focusedDuration))
                .font(.subheadline)
                .monospacedDigit()
                .foregroundStyle(.secondary)
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
        }
        .padding(.vertical, Theme.Spacing.small)
        .frame(minHeight: 44)
        .contentShape(.rect)
    }
}
