import SwiftUI
import WidgetKit

/// The Live Activity on the Lock Screen and in notification banners.
struct FocusLockScreenView: View {
    var attributes: FocusActivityAttributes
    var state: FocusActivityAttributes.ContentState

    var body: some View {
        let palette = OrbPalette.named(attributes.paletteName)

        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 14) {
                MiniOrb(palette: palette)
                    .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 2) {
                    Text(attributes.intention.isEmpty ? "Focusing" : attributes.intention)
                        .font(.system(.headline, design: .serif))
                        .lineLimit(1)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 8)

                SessionCountdown(state: state)
                    .font(.system(.title, design: .rounded))
                    .monospacedDigit()
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 120, alignment: .trailing)
            }

            SessionProgressBar(attributes: attributes, state: state, palette: palette)
        }
        .padding(16)
        .foregroundStyle(.white)
    }

    private var subtitle: String {
        switch state.phase {
        case .paused: "Paused"
        case .overtime: "Goal reached · in flow"
        case .focusing: state.depthTitle
        }
    }
}
