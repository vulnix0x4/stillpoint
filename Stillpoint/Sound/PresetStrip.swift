import SwiftUI

/// Horizontally scrolling preset mixes.
struct PresetStrip: View {
    var selectedName: String
    var apply: (SoundMix) -> Void

    var body: some View {
        ScrollView(.horizontal) {
            GlassEffectContainer(spacing: Theme.Spacing.small) {
                HStack(spacing: Theme.Spacing.small) {
                    ForEach(SoundMix.presets) { preset in
                        let isSelected = preset.name == selectedName
                        Button {
                            apply(preset)
                        } label: {
                            Text(preset.name)
                                .font(.subheadline)
                                .bold()
                                .padding(.horizontal, Theme.Spacing.medium)
                                .frame(minHeight: 44)
                        }
                        .buttonStyle(.plain)
                        .glassEffect(isSelected ? .regular.tint(.white.opacity(0.25)).interactive() : .regular.interactive(), in: .capsule)
                        .accessibilityAddTraits(isSelected ? .isSelected : [])
                    }
                }
                .padding(.horizontal, Theme.Spacing.hairline)
            }
        }
        .scrollIndicators(.hidden)
        .scrollClipDisabled()
        .sensoryFeedback(.selection, trigger: selectedName)
    }
}
