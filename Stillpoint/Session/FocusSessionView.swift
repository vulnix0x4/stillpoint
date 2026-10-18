import SwiftUI

/// The session itself: the orb, the time, and as little else as possible. Controls fade
/// away after a few quiet seconds and come back with a tap.
struct FocusSessionView: View {
    var palette: OrbPalette

    @Environment(SessionEngine.self) private var engine
    @Environment(\.accessibilityVoiceOverEnabled) private var isVoiceOverOn
    @AppStorage(PreferenceKey.hapticsEnabled) private var hapticsEnabled = PreferenceKey.Default.hapticsEnabled

    @State private var isChromeVisible = true
    @State private var interactionCount = 0
    @State private var isComposing = false
    @State private var isShowingMixer = false
    @State private var isShowingParkedToast = false

    var body: some View {
        ZStack {
            VStack(spacing: Theme.Spacing.large) {
                SessionTopBar(plan: engine.plan, openMixer: showMixer)
                    .opacity(chromeOpacity)
                    .allowsHitTesting(isChromeVisible)

                Spacer(minLength: 0)

                if !engine.plan.intention.isEmpty {
                    Text(engine.plan.intention)
                        .font(.intention)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .padding(.horizontal, Theme.Spacing.medium)
                        .accessibilityLabel("Intention: \(engine.plan.intention)")
                }

                LiveSessionDisplay(palette: palette, parkedCount: engine.parkedCount)

                Spacer(minLength: 0)

                SessionControls(
                    isPaused: engine.clock?.isPaused ?? false,
                    canFinishFreely: engine.goalReached,
                    onPark: startComposing,
                    onTogglePause: togglePause,
                    onEnd: finish
                )
                .opacity(chromeOpacity)
                .allowsHitTesting(isChromeVisible)
            }
            .padding(.horizontal, Theme.Spacing.large)
            .padding(.vertical, Theme.Spacing.medium)
            // The session stays put when the composer's keyboard appears.
            .ignoresSafeArea(.keyboard)

            if isShowingParkedToast {
                ParkedToast()
                    .frame(maxHeight: .infinity, alignment: .top)
                    .padding(.top, Theme.Spacing.xLarge * 2)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            if isComposing {
                Color.black.opacity(0.55)
                    .ignoresSafeArea()
                    .onTapGesture(perform: stopComposing)
                    .accessibilityHidden(true)
                    .transition(.opacity)

                ParkThoughtComposer(onPark: park, onCancel: stopComposing)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .contentShape(.rect)
        .simultaneousGesture(TapGesture().onEnded { registerInteraction() })
        .task(id: interactionCount) {
            await hideChromeAfterQuiet()
        }
        .sensoryFeedback(.success, trigger: engine.goalReached) { _, reached in
            hapticsEnabled && reached
        }
        .sensoryFeedback(.impact(weight: .light), trigger: engine.parkedCount) { _, _ in
            hapticsEnabled
        }
        .onChange(of: engine.parkedCount, showParkedToast)
        .sheet(isPresented: $isShowingMixer) {
            SoundscapeMixerView()
        }
        .animation(Theme.Motion.settle, value: isComposing)
        .persistentSystemOverlays(isChromeVisible ? .automatic : .hidden)
    }

    private var chromeOpacity: Double {
        isChromeVisible ? 1 : 0
    }

    // MARK: - Chrome

    private func registerInteraction() {
        interactionCount += 1
        if !isChromeVisible {
            withAnimation(Theme.Motion.reveal) {
                isChromeVisible = true
            }
        }
    }

    private func hideChromeAfterQuiet() async {
        try? await Task.sleep(for: .seconds(8))
        guard !Task.isCancelled, !isVoiceOverOn, !isComposing, !isShowingMixer,
              engine.clock?.isPaused == false
        else { return }
        withAnimation(Theme.Motion.fadeAway) {
            isChromeVisible = false
        }
    }

    // MARK: - Actions

    private func startComposing() {
        isComposing = true
        registerInteraction()
    }

    private func stopComposing() {
        isComposing = false
        registerInteraction()
    }

    private func park(_ text: String) {
        engine.parkThought(text)
        stopComposing()
    }

    private func togglePause() {
        engine.togglePause()
        registerInteraction()
    }

    private func finish() {
        engine.finish()
    }

    private func showMixer() {
        isShowingMixer = true
        registerInteraction()
    }

    private func showParkedToast() {
        withAnimation(Theme.Motion.settle) {
            isShowingParkedToast = true
        } completion: {
            Task {
                try? await Task.sleep(for: .seconds(1.6))
                withAnimation(Theme.Motion.settle) {
                    isShowingParkedToast = false
                }
            }
        }
    }
}
