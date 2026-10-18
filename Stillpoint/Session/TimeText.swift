import Foundation

/// Consistent time formatting across the app.
nonisolated enum TimeText {
    /// "24:59" or "1:04:59".
    static func clock(_ seconds: TimeInterval) -> String {
        let whole = max(0, Int(seconds))
        let duration = Duration.seconds(whole)
        return whole >= 3_600
            ? duration.formatted(.time(pattern: .hourMinuteSecond))
            : duration.formatted(.time(pattern: .minuteSecond))
    }

    /// "1h 12m" or "42m".
    static func short(_ seconds: TimeInterval) -> String {
        let minutes = max(0, Int((seconds / 60).rounded()))
        return Duration.seconds(minutes * 60).formatted(.units(allowed: [.hours, .minutes], width: .narrow))
    }

    /// "24 minutes, 59 seconds", for VoiceOver.
    static func spoken(_ seconds: TimeInterval) -> String {
        Duration.seconds(max(0, Int(seconds))).formatted(.units(allowed: [.hours, .minutes, .seconds], width: .wide))
    }
}
