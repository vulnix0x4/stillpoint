import SwiftUI

/// Soundscape and "breathe first" choices, side by side.
struct SessionOptionsRow: View {
    var mixName: String
    var isSilent: Bool
    @Binding var arriveFirst: Bool
    var tint: Color
    var openMixer: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: Theme.Spacing.small))
            : AnyLayout(HStackLayout(spacing: Theme.Spacing.small))

        GlassEffectContainer(spacing: Theme.Spacing.small) {
            layout {
                Button(action: openMixer) {
                    OptionLabel(
                        title: "Sound",
                        value: mixName,
                        symbol: isSilent ? "speaker.slash" : "speaker.wave.2"
                    )
                }
                .buttonStyle(.plain)
                .glassEffect(.regular.interactive(), in: .rect(cornerRadius: Theme.Radius.control))
                .accessibilityLabel("Soundscape, \(mixName)")

                Button(action: toggleArrival) {
                    OptionLabel(
                        title: "Breathe first",
                        value: arriveFirst ? "On" : "Off",
                        symbol: arriveFirst ? "wind" : "wind.circle"
                    )
                }
                .buttonStyle(.plain)
                .glassEffect(
                    arriveFirst ? .regular.tint(tint.opacity(0.35)).interactive() : .regular.interactive(),
                    in: .rect(cornerRadius: Theme.Radius.control)
                )
                .accessibilityLabel("Breathe for a minute first")
                .accessibilityValue(arriveFirst ? "On" : "Off")
                .accessibilityAddTraits(.isToggle)
            }
        }
        .sensoryFeedback(.selection, trigger: arriveFirst)
    }

    private func toggleArrival() {
        withAnimation(Theme.Motion.quick) {
            arriveFirst.toggle()
        }
    }
}
