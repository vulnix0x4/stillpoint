import SwiftUI

/// Done, partly, or not yet.
struct OutcomePicker: View {
    @Binding var selection: SessionOutcome?
    var tint: Color

    var body: some View {
        GlassEffectContainer(spacing: Theme.Spacing.small) {
            HStack(spacing: Theme.Spacing.small) {
                ForEach(SessionOutcome.allCases) { outcome in
                    let isSelected = selection == outcome
                    Button {
                        select(outcome)
                    } label: {
                        Label(outcome.title, systemImage: outcome.symbol)
                            .font(.subheadline)
                            .bold()
                            .foregroundStyle(isSelected ? Theme.ink : Color.primary)
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(.plain)
                    .glassEffect(isSelected ? .regular.tint(tint).interactive() : .regular.interactive(), in: .capsule)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
        }
        .labelStyle(.titleAndIcon)
    }

    private func select(_ outcome: SessionOutcome) {
        withAnimation(Theme.Motion.quick) {
            selection = selection == outcome ? nil : outcome
        }
    }
}
