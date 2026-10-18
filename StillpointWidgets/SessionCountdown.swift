import SwiftUI

/// A self-updating time display for the Live Activity. The system ticks it, so the activity
/// needs no updates to stay accurate.
struct SessionCountdown: View {
    var state: FocusActivityAttributes.ContentState

    var body: some View {
        switch state.phase {
        case .paused:
            Text(Duration.seconds(Int(state.frozenSeconds)).formatted(.time(pattern: .minuteSecond)))
        case .overtime:
            if let goalDate = state.goalDate {
                Text("+\(Text(goalDate, style: .timer))")
            } else {
                Text(state.effectiveStart, style: .timer)
            }
        case .focusing:
            if let goalDate = state.goalDate, goalDate > .now {
                Text(timerInterval: Date.now...goalDate, countsDown: true)
            } else {
                Text(state.effectiveStart, style: .timer)
            }
        }
    }
}
