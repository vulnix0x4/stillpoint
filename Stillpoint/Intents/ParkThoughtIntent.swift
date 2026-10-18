import AppIntents

/// Captures a thought without opening the app. If a session is running, the thought is
/// attached to it.
struct ParkThoughtIntent: AppIntent {
    static let title: LocalizedStringResource = "Park a Thought"
    static let description = IntentDescription("Saves a stray thought to Stillpoint so you can get back to what you were doing.")
    static let supportedModes: IntentModes = .background

    @Parameter(title: "Thought", requestValueDialog: "What's on your mind?")
    var text: String

    @Dependency private var engine: SessionEngine

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        engine.parkThought(text)
        return .result(dialog: "Parked. Back to it.")
    }
}
