import SwiftUI

/// Ending a session early should be a choice, not a slip. Hold for just over a second, while a
/// ring fills, to end. VoiceOver users get a normal activation.
struct HoldToEndButton: View {
    var action: () -> Void

    private static let holdDuration = 1.2

    @State private var progress = 0.0
    @State private var isPressing = false
    @State private var completions = 0

    var body: some View {
        VStack(spacing: Theme.Spacing.tight) {
            ZStack {
                Image(systemName: "stop.fill")
                    .font(.title2)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(.tint, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .padding(4)
            }
            .frame(width: 64, height: 64)
            .glassEffect(.regular.interactive(), in: .circle)

            Text(isPressing ? "Keep holding" : "Hold to end")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                .contentTransition(.opacity)
        }
        .frame(maxWidth: .infinity)
        .contentShape(.rect)
        .onLongPressGesture(minimumDuration: Self.holdDuration, maximumDistance: 40, perform: complete, onPressingChanged: pressingChanged)
        .sensoryFeedback(.impact(weight: .heavy), trigger: completions)
        .sensoryFeedback(.impact(weight: .light), trigger: isPressing) { _, pressing in pressing }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("End session")
        .accessibilityHint("Ends the session before the planned time")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(.default, action)
    }

    private func pressingChanged(_ pressing: Bool) {
        isPressing = pressing
        withAnimation(pressing ? .linear(duration: Self.holdDuration) : .easeOut(duration: 0.25)) {
            progress = pressing ? 1 : 0
        }
    }

    private func complete() {
        completions += 1
        action()
    }
}
