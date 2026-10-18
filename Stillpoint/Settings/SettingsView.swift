import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @AppStorage(PreferenceKey.dailyGoalMinutes) private var dailyGoal = PreferenceKey.Default.dailyGoalMinutes
    @AppStorage(PreferenceKey.arriveByDefault) private var arriveByDefault = PreferenceKey.Default.arriveByDefault
    @AppStorage(PreferenceKey.breathPattern) private var breathPattern = BreathPattern.sigh
    @AppStorage(PreferenceKey.completionBehavior) private var completionBehavior = CompletionBehavior.keepFlowing
    @AppStorage(PreferenceKey.palette) private var paletteName = OrbPalette.ember.rawValue
    @AppStorage(PreferenceKey.chimeEnabled) private var chimeEnabled = PreferenceKey.Default.chimeEnabled
    @AppStorage(PreferenceKey.hapticsEnabled) private var hapticsEnabled = PreferenceKey.Default.hapticsEnabled
    @AppStorage(PreferenceKey.keepScreenAwake) private var keepScreenAwake = PreferenceKey.Default.keepScreenAwake
    @AppStorage(PreferenceKey.liveActivitiesEnabled) private var liveActivitiesEnabled = PreferenceKey.Default.liveActivitiesEnabled

    @State private var isConfirmingErase = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    PalettePicker(selection: $paletteName)
                        .listRowInsets(EdgeInsets(top: Theme.Spacing.medium, leading: Theme.Spacing.medium, bottom: Theme.Spacing.medium, trailing: Theme.Spacing.medium))
                } header: {
                    Text("Colour")
                }

                Section {
                    LabeledContent("Daily goal") {
                        Stepper(value: $dailyGoal, in: 15...600, step: 15) {
                            Text(TimeText.short(Double(dailyGoal) * 60))
                                .monospacedDigit()
                        }
                        .fixedSize()
                    }
                    Picker("When time is up", selection: $completionBehavior) {
                        ForEach(CompletionBehavior.allCases) { behavior in
                            Text(behavior.title).tag(behavior)
                        }
                    }
                } header: {
                    Text("Sessions")
                } footer: {
                    Text("Keep flowing rings the bell and lets you carry on, so a good stretch is never cut short.")
                }

                Section {
                    Toggle("Breathe before focusing", isOn: $arriveByDefault)
                    Picker("Pattern", selection: $breathPattern) {
                        ForEach(BreathPattern.allCases) { pattern in
                            Text(pattern.title).tag(pattern)
                        }
                    }
                } header: {
                    Text("Arriving")
                } footer: {
                    Text(breathPattern.summary)
                }

                Section("Feedback") {
                    Toggle("Singing bowl at start and end", isOn: $chimeEnabled)
                    Toggle("Haptics", isOn: $hapticsEnabled)
                    Toggle("Keep screen awake in sessions", isOn: $keepScreenAwake)
                    Toggle("Live Activity", isOn: $liveActivitiesEnabled)
                }

                Section {
                    VStack(alignment: .leading, spacing: Theme.Spacing.small) {
                        Text("Stillpoint")
                            .font(.sectionTitle)
                        Text("A quiet place for one thing at a time. No accounts, no tracking, no cloud. Everything stays on this device.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, Theme.Spacing.tight)
                    LabeledContent("Version", value: Bundle.main.appVersion)
                }

                #if DEBUG
                Section("Developer") {
                    Button("Generate Sample History", action: generateSampleData)
                    Button("Erase All Data", role: .destructive, action: confirmErase)
                        .confirmationDialog("Erase all sessions and thoughts?", isPresented: $isConfirmingErase, titleVisibility: .visible) {
                            Button("Erase Everything", role: .destructive, action: eraseAll)
                        }
                }
                #endif
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: close)
                }
            }
            .onChange(of: dailyGoal, refreshWidgets)
            .onChange(of: paletteName, refreshWidgets)
        }
    }

    private func close() {
        dismiss()
    }

    private func refreshWidgets() {
        WidgetSync.refresh(using: modelContext)
    }

    private func generateSampleData() {
        SampleDataGenerator(seed: UInt64.random(in: 1...1_000_000)).populate(modelContext)
        refreshWidgets()
    }

    private func confirmErase() {
        isConfirmingErase = true
    }

    private func eraseAll() {
        try? modelContext.delete(model: FocusSession.self)
        try? modelContext.delete(model: ParkedThought.self)
        try? modelContext.save()
        refreshWidgets()
    }
}
