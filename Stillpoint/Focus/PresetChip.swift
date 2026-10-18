import SwiftUI

/// A small glass pill for a preset value.
struct PresetChip: View {
    var title: String
    var accessibilityTitle: String
    var isSelected: Bool
    var tint: Color
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(.body, design: .rounded))
                .bold()
                .monospacedDigit()
                .padding(.horizontal, Theme.Spacing.small)
                .frame(minWidth: 44, minHeight: 44)
                .foregroundStyle(isSelected ? Theme.ink : Color.primary)
        }
        .buttonStyle(.plain)
        .glassEffect(isSelected ? .regular.tint(tint).interactive() : .regular.interactive(), in: .capsule)
        .accessibilityLabel(accessibilityTitle)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
