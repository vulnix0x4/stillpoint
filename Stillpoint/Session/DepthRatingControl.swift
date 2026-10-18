import SwiftUI

/// Five glowing dots, from scattered to absorbed.
struct DepthRatingControl: View {
    @Binding var rating: Int?
    var palette: OrbPalette

    static let descriptions = ["Scattered", "Restless", "Steady", "Immersed", "Absorbed"]

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            HStack(spacing: 0) {
                ForEach(1...5, id: \.self) { value in
                    Button {
                        select(value)
                    } label: {
                        Circle()
                            .fill(isLit(value) ? AnyShapeStyle(RadialGradient(colors: [palette.core, palette.mid], center: .center, startRadius: 0, endRadius: 18)) : AnyShapeStyle(Color.white.opacity(0.1)))
                            .frame(width: 20 + Double(value) * 3, height: 20 + Double(value) * 3)
                            .shadow(color: isLit(value) ? palette.mid.opacity(0.7) : .clear, radius: 8)
                            .frame(maxWidth: .infinity, minHeight: 52)
                            .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Self.descriptions[value - 1])
                }
            }
            Text(rating.map { Self.descriptions[$0 - 1] } ?? "Tap to rate")
                .font(.subheadline)
                .foregroundStyle(rating == nil ? .secondary : .primary)
                .frame(maxWidth: .infinity)
                .contentTransition(.opacity)
        }
        .animation(Theme.Motion.quick, value: rating)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Focus depth")
        .accessibilityValue(rating.map { "\(Self.descriptions[$0 - 1]), \($0) of 5" } ?? "Not rated")
        .accessibilityAdjustableAction(adjust)
    }

    private func isLit(_ value: Int) -> Bool {
        value <= (rating ?? 0)
    }

    private func select(_ value: Int) {
        rating = rating == value ? nil : value
    }

    private func adjust(_ direction: AccessibilityAdjustmentDirection) {
        switch direction {
        case .increment: rating = min(5, (rating ?? 0) + 1)
        case .decrement: rating = max(1, (rating ?? 2) - 1)
        @unknown default: break
        }
    }
}
