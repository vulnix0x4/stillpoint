import SwiftUI

/// Park a thought, pause, and end. Ending early takes a deliberate hold; once the goal is
/// reached, finishing is a simple tap.
struct SessionControls: View {
    var isPaused: Bool
    var canFinishFreely: Bool
    var onPark: () -> Void
    var onTogglePause: () -> Void
    var onEnd: () -> Void

    var body: some View {
        GlassEffectContainer(spacing: Theme.Spacing.large) {
            HStack(alignment: .top, spacing: Theme.Spacing.small) {
                Button("Park thought", systemImage: "tray.and.arrow.down", action: onPark)
                    .labelStyle(StackedLabelStyle())

                Button(isPaused ? "Resume" : "Pause", systemImage: isPaused ? "play.fill" : "pause.fill", action: onTogglePause)
                    .labelStyle(StackedLabelStyle(isProminent: isPaused))
                    .contentTransition(.symbolEffect(.replace))

                if canFinishFreely {
                    Button("Finish", systemImage: "checkmark", action: onEnd)
                        .labelStyle(StackedLabelStyle(isProminent: true))
                        .transition(.scale.combined(with: .opacity))
                } else {
                    HoldToEndButton(action: onEnd)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .buttonStyle(.plain)
        }
        .animation(Theme.Motion.settle, value: canFinishFreely)
        .animation(Theme.Motion.quick, value: isPaused)
    }
}
