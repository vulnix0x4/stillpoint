import SwiftUI

/// Four small living orbs to choose the app's colour.
struct PalettePicker: View {
    @Binding var selection: String

    var body: some View {
        HStack(spacing: Theme.Spacing.medium) {
            ForEach(OrbPalette.allCases) { palette in
                let isSelected = palette.rawValue == selection
                Button {
                    select(palette)
                } label: {
                    VStack(spacing: Theme.Spacing.tight) {
                        Circle()
                            .fill(RadialGradient(colors: [palette.core, palette.mid, palette.rim], center: UnitPoint(x: 0.4, y: 0.35), startRadius: 0, endRadius: 34))
                            .frame(width: 52, height: 52)
                            .shadow(color: palette.mid.opacity(isSelected ? 0.8 : 0), radius: 10)
                            .overlay {
                                Circle()
                                    .strokeBorder(Color.white.opacity(isSelected ? 0.9 : 0), lineWidth: 2)
                                    .padding(-5)
                            }
                        Text(palette.title)
                            .font(.caption)
                            .foregroundStyle(isSelected ? .primary : .secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(palette.title)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .sensoryFeedback(.selection, trigger: selection)
    }

    private func select(_ palette: OrbPalette) {
        withAnimation(Theme.Motion.settle) {
            selection = palette.rawValue
        }
    }
}
