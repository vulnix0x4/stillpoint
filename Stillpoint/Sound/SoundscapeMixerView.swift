import SwiftUI

/// Presets and a per-layer mixer. Plays a live preview while open.
struct SoundscapeMixerView: View {
    @Environment(SoundscapeEngine.self) private var sound
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        @Bindable var sound = sound

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.large) {
                    PresetStrip(selectedName: sound.mix.name, apply: sound.apply)

                    VStack(spacing: Theme.Spacing.tight) {
                        ForEach(SoundLayer.allCases) { layer in
                            SoundLayerRow(layer: layer, level: sound.mix.level(for: layer)) { level in
                                sound.setLevel(level, for: layer)
                            }
                        }
                    }
                    .cardSurface()

                    if sound.mix.level(for: .binaural) > 0.01 {
                        BinauralBandPicker(selection: sound.band, select: sound.setBand)
                            .cardSurface()
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    LabeledContent {
                        Slider(value: $sound.volume, in: 0...1)
                            .frame(maxWidth: 220)
                    } label: {
                        Label("Volume", systemImage: "speaker.wave.3")
                    }
                    .cardSurface()

                    Text("Every sound here is synthesised live on your device. Nothing loops, so nothing repeats.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, Theme.Spacing.small)
                }
                .padding(Theme.Spacing.medium)
                .animation(Theme.Motion.settle, value: sound.mix.level(for: .binaural) > 0.01)
            }
            .navigationTitle("Soundscape")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: close)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationBackground(.thinMaterial)
        .onAppear(perform: startPreview)
        .onDisappear(perform: endPreview)
    }

    private func close() {
        dismiss()
    }

    private func startPreview() {
        sound.acquire(.preview)
    }

    private func endPreview() {
        sound.release(.preview)
    }
}
