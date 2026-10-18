import SwiftUI

/// A round glass icon with a small caption beneath it.
struct StackedLabelStyle: LabelStyle {
    var isProminent = false

    func makeBody(configuration: Configuration) -> some View {
        VStack(spacing: Theme.Spacing.tight) {
            configuration.icon
                .font(.title2)
                .foregroundStyle(isProminent ? Theme.ink : Color.primary)
                .frame(width: 64, height: 64)
                .glassEffect(isProminent ? .regular.tint(.white.opacity(0.85)).interactive() : .regular.interactive(), in: .circle)
            configuration.title
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        }
        .frame(maxWidth: .infinity)
        .contentShape(.rect)
    }
}
