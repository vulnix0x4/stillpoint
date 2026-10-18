import ActivityKit
import Foundation
import os

/// Starts, updates and ends the focus Live Activity.
///
/// `Activity` isn't `Sendable`, so only identifiers cross into async work; each async helper
/// looks its activities up again on its own. Identifiers to end are captured synchronously, so
/// ending an old activity can never race with, and end, a newly started one.
final class LiveActivityController {
    private typealias FocusActivity = Activity<FocusActivityAttributes>
    private var activityID: String?
    private let logger = Logger(subsystem: "dev.stillpoint", category: "live-activity")

    func start(attributes: FocusActivityAttributes, state: FocusActivityAttributes.ContentState) {
        end()
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        do {
            let activity = try FocusActivity.request(
                attributes: attributes,
                content: ActivityContent(state: state, staleDate: nil),
                pushType: nil
            )
            activityID = activity.id
        } catch {
            logger.error("Couldn't start Live Activity: \(error.localizedDescription)")
        }
    }

    var isRunning: Bool {
        activityID != nil
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

    /// Ends every activity that exists right now.
    func end() {
        activityID = nil
        let existing = FocusActivity.activities.map(\.id)
        guard !existing.isEmpty else { return }
        Task {
            await Self.end(activityIDs: existing)
        }
    }

    private nonisolated static func update(activityID: String, content: ActivityContent<FocusActivityAttributes.ContentState>) async {
        guard let activity = FocusActivity.activities.first(where: { $0.id == activityID }) else { return }
        await activity.update(content)
    }

    private nonisolated static func end(activityIDs: [String]) async {
        for activity in FocusActivity.activities where activityIDs.contains(activity.id) {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }
}
