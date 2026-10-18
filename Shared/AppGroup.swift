import Foundation

/// The app group shared between Stillpoint and its widget extension.
nonisolated enum AppGroup {
    static let identifier = "group.dev.stillpoint.Stillpoint"

    /// Shared defaults. Falls back to the standard store if the group container is unavailable,
    /// which keeps previews and tests working.
    static var defaults: UserDefaults {
        UserDefaults(suiteName: identifier) ?? .standard
    }
}
