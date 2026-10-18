import SwiftUI

/// Breathing on its own, for whenever you need to come back to yourself.
struct StandaloneBreathingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(SoundscapeEngine.self) private var sound
    @AppStorage(PreferenceKey.palette) private var paletteName = OrbPalette.ember.rawValue
    @AppStorage(PreferenceKey.breathPattern) private var pattern = BreathPattern.sigh

    var body: some View {
        let palette = OrbPalette.named(paletteName)

        ZStack {
            AmbientBackground(palette: palette)

            VStack(spacing: Theme.Spacing.large) {
                HStack {
                    Menu {
                        Picker("Pattern", selection: $pattern) {
                            ForEach(BreathPattern.allCases) { pattern in
                                Text(pattern.title).tag(pattern)
                            }
                        }
                    } label: {
                        Label(pattern.title, systemImage: "wind")
                            .font(.subheadline)
                            .padding(.horizontal, Theme.Spacing.medium)
                            .frame(minHeight: 44)
                            .glassEffect(.regular.interactive(), in: .capsule)
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Button("Done", action: close)
                        .buttonStyle(.glassProminent)
                        .controlSize(.large)
                }

                Text(pattern.summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .contentTransition(.opacity)

                Spacer(minLength: 0)

                BreathingExerciseView(pattern: pattern, cycles: nil, palette: palette)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, Theme.Spacing.large)
            .padding(.vertical, Theme.Spacing.medium)
        }
        .animation(Theme.Motion.settle, value: pattern)
        .tint(palette.accent)
        .onAppear(perform: startSound)
        .onDisappear(perform: stopSound)
        .preferredColorScheme(.dark)
    }

    private func close() {
        dismiss()
    }

    private func startSound() {
        sound.acquire(.breathing)
    }

    private func stopSound() {
        sound.release(.breathing)
    }
}
