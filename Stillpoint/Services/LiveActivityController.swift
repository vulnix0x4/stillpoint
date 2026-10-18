import ActivityKit
import Foundation

/// Starts, updates and ends the focus Live Activity.
///
/// `Activity` isn't `Sendable`, so only its identifier crosses into async work; each async
/// helper looks the activity up again on its own.
final class LiveActivityController {
    private typealias FocusActivity = Activity<FocusActivityAttributes>
    private var activityID: String?

    func start(attributes: FocusActivityAttributes, state: FocusActivityAttributes.ContentState) {
        end()
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let activity = try? FocusActivity.request(
            attributes: attributes,
            content: ActivityContent(state: state, staleDate: nil),
            pushType: nil
        )
        activityID = activity?.id
    }

    /// Re-attaches to an activity that outlived a previous launch.
    func adoptExisting() {
        activityID = FocusActivity.activities.first?.id
    }

    func update(_ state: FocusActivityAttributes.ContentState) {
        guard let activityID else { return }
        let content = ActivityContent(state: state, staleDate: nil)
        Task {
            await Self.update(activityID: activityID, content: content)
        }
    }

    func end() {
        activityID = nil
        Task {
            await Self.endAll()
        }
    }

    private nonisolated static func update(activityID: String, content: ActivityContent<FocusActivityAttributes.ContentState>) async {
        guard let activity = FocusActivity.activities.first(where: { $0.id == activityID }) else { return }
        await activity.update(content)
    }

    private nonisolated static func endAll() async {
        for activity in FocusActivity.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }
}
