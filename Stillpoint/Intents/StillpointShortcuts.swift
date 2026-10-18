import AppIntents

struct StillpointShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartFocusIntent(),
            phrases: [
                "Start focusing in \(.applicationName)",
                "Begin a \(.applicationName) session",
            ],
            shortTitle: "Start Focus",
            systemImageName: "circle.circle"
        )
        AppShortcut(
            intent: ParkThoughtIntent(),
            phrases: [
                "Park a thought in \(.applicationName)",
            ],
            shortTitle: "Park a Thought",
            systemImageName: "tray.and.arrow.down"
        )
    }

    static let shortcutTileColor: ShortcutTileColor = .purple
}
