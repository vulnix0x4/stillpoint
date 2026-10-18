import Foundation

/// UserDefaults keys and their defaults, shared by `@AppStorage` and non-view code.
enum PreferenceKey {
    static let hasOnboarded = "hasOnboarded"
    static let dailyGoalMinutes = "dailyGoalMinutes"
    static let defaultDurationMinutes = "defaultDurationMinutes"
    static let isFlowSelected = "isFlowSelected"
    static let arriveByDefault = "arriveByDefault"
    static let breathPattern = "breathPattern"
    static let palette = "palette"
    static let keepScreenAwake = "keepScreenAwake"
    static let chimeEnabled = "chimeEnabled"
    static let hapticsEnabled = "hapticsEnabled"
    static let liveActivitiesEnabled = "liveActivitiesEnabled"
    static let completionBehavior = "completionBehavior"
    static let soundMix = "soundMix"
    static let soundVolume = "soundVolume"
    static let binauralBand = "binauralBand"

    enum Default {
        static let dailyGoalMinutes = 120
        static let defaultDurationMinutes = 25
        static let arriveByDefault = true
        static let keepScreenAwake = true
        static let chimeEnabled = true
        static let hapticsEnabled = true
        static let liveActivitiesEnabled = true
        static let soundVolume = 0.8
    }
}

extension UserDefaults {
    /// Reads a Bool preference, honouring a default when the key has never been written.
    func bool(forKey key: String, default defaultValue: Bool) -> Bool {
        object(forKey: key) == nil ? defaultValue : bool(forKey: key)
    }

    /// Reads an Int preference, honouring a default when the key has never been written.
    func integer(forKey key: String, default defaultValue: Int) -> Int {
        object(forKey: key) == nil ? defaultValue : integer(forKey: key)
    }
}
