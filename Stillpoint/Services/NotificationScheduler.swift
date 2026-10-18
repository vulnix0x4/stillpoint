import UserNotifications

/// Schedules the "session complete" notification that covers the case where the app is
/// suspended when time runs out.
struct NotificationScheduler {
    private static let completionIdentifier = "stillpoint.session.complete"
    private var center: UNUserNotificationCenter { .current() }

    /// Asks for permission. Returns whether alerts are allowed.
    @discardableResult
    func requestAuthorization() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound])
        } catch {
            return false
        }
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    func scheduleCompletion(at date: Date, intention: String) async {
        cancelCompletion()
        let content = UNMutableNotificationContent()
        content.title = "Time's up"
        content.body = intention.isEmpty
            ? "Take a breath before you move on."
            : "\u{201C}\(intention)\u{201D}. Take a moment to reflect."
        content.sound = .default

        let interval = max(1, date.timeIntervalSinceNow)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(identifier: Self.completionIdentifier, content: content, trigger: trigger)
        try? await center.add(request)
    }

    func cancelCompletion() {
        center.removePendingNotificationRequests(withIdentifiers: [Self.completionIdentifier])
        center.removeDeliveredNotifications(withIdentifiers: [Self.completionIdentifier])
    }
}
