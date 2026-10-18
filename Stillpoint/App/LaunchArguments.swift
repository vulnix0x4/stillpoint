import Foundation
import SwiftData

/// Launch arguments used for demos, screenshots and UI testing.
///
/// - `-seedSampleData`: fills an empty store with ten weeks of realistic history.
/// - `-skipOnboarding`: starts on the main screen.
enum LaunchArguments {
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
