import SwiftUI

/// About a minute of guided breathing before focus begins.
struct ArrivalBreathingView: View {
    var pattern: BreathPattern
    var intention: String
    var palette: OrbPalette
    var onFinish: () -> Void
    var onCancel: () -> Void

    var body: some View {
        VStack(spacing: Theme.Spacing.large) {
            HStack {
                Button("Cancel", action: onCancel)
                    .buttonStyle(.glass)
                Spacer()
                Button("Skip", systemImage: "forward.fill", action: onFinish)
                    .buttonStyle(.glass)
            }
            .controlSize(.large)

            VStack(spacing: Theme.Spacing.hairline) {
                Text("Arrive")
                    .font(.sectionTitle)
                Text(pattern.title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            BreathingExerciseView(
                pattern: pattern,
                cycles: pattern.cycles(toFill: 60),
                palette: palette,
                onComplete: onFinish
            )

            Spacer(minLength: 0)

            if !intention.isEmpty {
                VStack(spacing: Theme.Spacing.hairline) {
                    Text("Then")
                        .font(.caption)
                        .textCase(.uppercase)
                        .kerning(1.5)
                        .foregroundStyle(.tertiary)
                    Text(intention)
                        .font(.intention)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, Theme.Spacing.large)
        .padding(.vertical, Theme.Spacing.medium)
    }
}
