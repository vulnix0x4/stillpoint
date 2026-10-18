import WidgetKit

/// Reads the snapshot the app writes, and schedules a refresh at midnight so "today"
/// rolls over even if the app isn't opened.
struct TodayProvider: TimelineProvider {
    func placeholder(in context: Context) -> TodayEntry {
        TodayEntry(date: .now, snapshot: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (TodayEntry) -> Void) {
        let snapshot = context.isPreview ? .placeholder : (WidgetSnapshot.load() ?? .empty)
        completion(TodayEntry(date: .now, snapshot: snapshot.adjusted(to: .now)))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodayEntry>) -> Void) {
        let now = Date.now
        let stored = WidgetSnapshot.load() ?? .empty
        let calendar = Calendar.current
        let midnight = calendar.nextDate(after: now, matching: DateComponents(hour: 0, minute: 0), matchingPolicy: .nextTime) ?? now.addingTimeInterval(3_600)

        let entries = [
            TodayEntry(date: now, snapshot: stored.adjusted(to: now)),
            TodayEntry(date: midnight, snapshot: stored.adjusted(to: midnight)),
        ]
        completion(Timeline(entries: entries, policy: .after(midnight.addingTimeInterval(60))))
    }
}
