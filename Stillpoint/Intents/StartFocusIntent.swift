import AppIntents

/// Starts a session from Shortcuts, Siri, Spotlight or the Action button.
struct StartFocusIntent: AppIntent {
    static let title: LocalizedStringResource = "Start Focus Session"
    static let description = IntentDescription("Opens Stillpoint and begins a focus session.")
    static let supportedModes: IntentModes = .foreground

    @Parameter(title: "Minutes", description: "Leave empty for an open-ended flow session.", inclusiveRange: (5, 240))
    var minutes: Int?

    @Parameter(title: "Intention")
    var intention: String?

    @Dependency private var engine: SessionEngine

    static var parameterSummary: some ParameterSummary {
        Summary("Focus for \(\.$minutes) minutes on \(\.$intention)")
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        engine.startFromShortcut(minutes: minutes, intention: intention ?? "")
        return .result()
    }
}
