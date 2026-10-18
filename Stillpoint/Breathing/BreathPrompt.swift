import SwiftUI

/// "Breathe in", a count, and which round this is.
struct BreathPrompt: View {
    var state: BreathState
    var totalCycles: Int?

    var body: some View {
        VStack(spacing: Theme.Spacing.small) {
            Text(state.phase.prompt)
                .font(.display)
                .contentTransition(.opacity)
                .animation(.easeInOut(duration: 0.4), value: state.phaseIndex)
                .id(state.phase.prompt)

            Text(Int(state.phaseRemaining.rounded(.up)), format: .number)
                .font(.system(.title2, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.secondary)

            if let totalCycles {
                Text("Round \(min(state.cycle + 1, totalCycles)) of \(totalCycles)")
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
                    .monospacedDigit()
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(state.phase.prompt)
    }
}
