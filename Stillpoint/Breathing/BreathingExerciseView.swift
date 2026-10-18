import SwiftUI

/// The orb breathes; you breathe with it. Runs a pattern for a number of cycles, or forever.
struct BreathingExerciseView: View {
    var pattern: BreathPattern
    /// `nil` runs until dismissed.
    var cycles: Int?
    var palette: OrbPalette
    var onComplete: () -> Void = {}

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage(PreferenceKey.hapticsEnabled) private var hapticsEnabled = PreferenceKey.Default.hapticsEnabled
    @State private var start = Date.now
    @State private var haptics: BreathHaptics?

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 60)) { context in
            let elapsed = context.date.timeIntervalSince(start)
            let state = BreathState(pattern: pattern, elapsed: elapsed)

            VStack(spacing: Theme.Spacing.xLarge) {
                OrbRenderer(
                    palette: palette,
                    time: elapsed * (reduceMotion ? 0.1 : 0.6),
                    turbulence: 0.12 + 0.12 * (1 - state.fullness),
                    energy: state.fullness * 0.55
                )
                .scaleEffect(reduceMotion ? 1 : 0.6 + 0.4 * state.fullness)
                .opacity(reduceMotion ? 0.55 + 0.45 * state.fullness : 1)
                .aspectRatio(1, contentMode: .fit)
                .frame(maxWidth: 380)

                BreathPrompt(state: state, totalCycles: cycles)
            }
        }
        .task(id: pattern) {
            await guide()
        }
        .onDisappear {
            haptics?.stop()
        }
    }

    /// Walks through the phases in real time: haptics, VoiceOver cues and completion.
    private func guide() async {
        start = .now
        if hapticsEnabled, haptics == nil {
            haptics = BreathHaptics()
        }
        var offset: TimeInterval = 0
        var completed = 0
        while !Task.isCancelled {
            for phase in pattern.phases {
                if hapticsEnabled {
                    haptics?.play(phase)
                }
                AccessibilityNotification.Announcement(phase.prompt).post()
                offset += phase.duration
                let wait = start.addingTimeInterval(offset).timeIntervalSinceNow
                try? await Task.sleep(for: .seconds(max(0, wait)))
                if Task.isCancelled { return }
            }
            completed += 1
            if let cycles, completed >= cycles {
                haptics?.stop()
                onComplete()
                return
            }
        }
    }
}
