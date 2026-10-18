import Foundation
import SwiftData

/// Launch arguments used for demos, screenshots and UI testing.
///
/// - `-seedSampleData`: fills an empty store with ten weeks of realistic history.
/// - `-skipOnboarding`: starts on the main screen.
/// - `-fastSessions` (debug builds only): a planned minute lasts two seconds, for checking the
///   end of a session without waiting for it.
nonisolated enum LaunchArguments {
    static let secondsPerMinute: TimeInterval = {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains("-fastSessions") ? 2 : 60
        #else
        60
        #endif
    }()

    @MainActor
    static func apply(to context: ModelContext, arguments: [String] = ProcessInfo.processInfo.arguments) {
        if arguments.contains("-skipOnboarding") {
            UserDefaults.standard.set(true, forKey: PreferenceKey.hasOnboarded)
        }
        if arguments.contains("-seedSampleData") {
            let existing = (try? context.fetchCount(FetchDescriptor<FocusSession>())) ?? 0
            if existing == 0 {
                SampleDataGenerator().populate(context)
            }
        }
    }
}
