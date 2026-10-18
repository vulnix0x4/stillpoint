import SwiftUI

/// Quick lengths, plus open-ended flow.
struct DurationPresets: View {
    @Binding var minutes: Int
    @Binding var isFlow: Bool
    var tint: Color

    private static let presets = [15, 25, 45, 60, 90]

    var body: some View {
        // At large text sizes the row no longer fits, so it scrolls instead of squeezing.
        ViewThatFits(in: .horizontal) {
            chips
            ScrollView(.horizontal) {
                chips
                    .padding(.horizontal, Theme.Spacing.hairline)
            }
            .scrollIndicators(.hidden)
            .scrollClipDisabled()
        }
        .sensoryFeedback(.selection, trigger: isFlow)
    }

    private var chips: some View {
        GlassEffectContainer(spacing: Theme.Spacing.small) {
            HStack(spacing: Theme.Spacing.tight) {
                ForEach(Self.presets, id: \.self) { preset in
                    PresetChip(
                        title: "\(preset)",
                        accessibilityTitle: "\(preset) minutes",
                        isSelected: !isFlow && minutes == preset,
                        tint: tint
                    ) {
                        select(preset)
                    }
                }
                PresetChip(title: "∞", accessibilityTitle: "Open-ended flow", isSelected: isFlow, tint: tint, action: selectFlow)
            }
        }
    }

    private func select(_ preset: Int) {
        withAnimation(Theme.Motion.quick) {
            isFlow = false
            minutes = preset
        }
    }

    private func selectFlow() {
        withAnimation(Theme.Motion.quick) {
            isFlow = true
        }
    }
}
