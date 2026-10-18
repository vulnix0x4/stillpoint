import SwiftData
import SwiftUI

/// Where every session begins: choose a length, name the intention, set the sound, begin.
struct FocusHomeView: View {
    @Environment(SessionEngine.self) private var engine
    @Environment(SoundscapeEngine.self) private var sound
    @Query(filter: #Predicate<FocusSession> { $0.isFinalized }) private var sessions: [FocusSession]

    @AppStorage(PreferenceKey.palette) private var paletteName = OrbPalette.ember.rawValue
    @AppStorage(PreferenceKey.defaultDurationMinutes) private var minutes = PreferenceKey.Default.defaultDurationMinutes
    @AppStorage(PreferenceKey.isFlowSelected) private var isFlow = false
    @AppStorage(PreferenceKey.arriveByDefault) private var arriveFirst = PreferenceKey.Default.arriveByDefault
    @AppStorage(PreferenceKey.breathPattern) private var breathPattern = BreathPattern.sigh
    @AppStorage(PreferenceKey.dailyGoalMinutes) private var dailyGoal = PreferenceKey.Default.dailyGoalMinutes

    @State private var intention = ""
    @State private var isShowingMixer = false
    @State private var isShowingSettings = false
    @State private var isShowingBreathing = false
    @FocusState private var isEditingIntention: Bool

    var body: some View {
        let palette = OrbPalette.named(paletteName)
        let today = TodaySummary(records: sessions.map(\.record), now: .now)

        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.medium) {
                    HomeHeader(streak: today.streak, now: .now)

                    TodayProgress(minutes: today.minutes, goal: dailyGoal, sessions: today.sessions, palette: palette)

                    DurationPicker(minutes: $minutes, isFlow: $isFlow, palette: palette)
                        .frame(maxWidth: 262)

                    DurationPresets(minutes: $minutes, isFlow: $isFlow, tint: palette.accent)

                    IntentionField(text: $intention, focus: $isEditingIntention)

                    SessionOptionsRow(
                        mixName: sound.mix.isSilent ? "Silence" : sound.mix.name,
                        isSilent: sound.mix.isSilent,
                        arriveFirst: $arriveFirst,
                        tint: palette.accent,
                        openMixer: showMixer
                    )
                }
                .padding(.horizontal, Theme.Spacing.large)
                .padding(.bottom, Theme.Spacing.medium)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
            .safeAreaInset(edge: .bottom) {
                Button(action: begin) {
                    Text("Begin")
                        .font(.title3)
                        .bold()
                        .foregroundStyle(Theme.ink)
                        .frame(maxWidth: .infinity, minHeight: 36)
                }
                .buttonStyle(.glassProminent)
                .controlSize(.large)
                .padding(.horizontal, Theme.Spacing.large)
                .padding(.bottom, Theme.Spacing.small)
            }
            .background {
                AmbientBackground(palette: palette)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Breathe", systemImage: "wind", action: showBreathing)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Settings", systemImage: "gearshape", action: showSettings)
                }
            }
            .sheet(isPresented: $isShowingMixer) {
                SoundscapeMixerView()
            }
            .sheet(isPresented: $isShowingSettings) {
                SettingsView()
            }
            .fullScreenCover(isPresented: $isShowingBreathing) {
                StandaloneBreathingView()
            }
        }
    }

    private func begin() {
        isEditingIntention = false
        let plan = SessionPlan(
            intention: intention,
            plannedMinutes: isFlow ? nil : minutes,
            arriveFirst: arriveFirst,
            breathPattern: breathPattern
        )
        Task {
            // Ask before the session starts, so the prompt never lands on top of it and the
            // completion notification can be scheduled.
            let scheduler = NotificationScheduler()
            if await scheduler.authorizationStatus() == .notDetermined {
                await scheduler.requestAuthorization()
            }
            engine.begin(plan)
            intention = ""
        }
    }

    private func showMixer() {
        isShowingMixer = true
    }

    private func showSettings() {
        isShowingSettings = true
    }

    private func showBreathing() {
        isShowingBreathing = true
    }
}

#Preview {
    let container = ModelContainerFactory.make(inMemory: true)
    let sound = SoundscapeEngine()
    FocusHomeView()
        .environment(SessionEngine(modelContext: container.mainContext, sound: sound))
        .environment(sound)
        .modelContainer(container)
        .preferredColorScheme(.dark)
}
