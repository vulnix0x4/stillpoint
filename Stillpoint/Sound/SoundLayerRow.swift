import SwiftUI

/// One layer of the mix with its level slider.
struct SoundLayerRow: View {
    var layer: SoundLayer
    var level: Double
    var setLevel: (Double) -> Void

    @State private var draft = 0.0

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.tight) {
            HStack(spacing: Theme.Spacing.small) {
                Image(systemName: layer.symbol)
                    .font(.title3)
                    .frame(width: 30)
                    .foregroundStyle(level > 0.01 ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
                    .symbolEffect(.variableColor.iterative, options: .repeat(.continuous), isActive: level > 0.01)
                VStack(alignment: .leading, spacing: 0) {
                    Text(layer.title)
                        .font(.headline)
                    Text(layer.detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Slider(value: $draft, in: 0...1)
                .accessibilityLabel(layer.title)
                .accessibilityValue(draft < 0.01 ? "Off" : draft.formatted(.percent.precision(.fractionLength(0))))
        }
        .padding(.vertical, Theme.Spacing.tight)
        .onAppear(perform: syncDraft)
        .onChange(of: level, syncDraft)
        .onChange(of: draft) { _, newValue in
            if abs(newValue - level) > 0.001 {
                setLevel(newValue)
            }
        }
    }

    private func syncDraft() {
        draft = level
    }
}
