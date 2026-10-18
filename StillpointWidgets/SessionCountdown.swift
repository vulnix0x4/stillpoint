import SwiftUI

/// A self-updating time display for the Live Activity. The system ticks it, so the activity
/// needs no updates to stay accurate.
struct SessionCountdown: View {
    var state: FocusActivityAttributes.ContentState

    var body: some View {
        switch state.phase {
        case .paused:
            let frozen = Duration.seconds(Int(state.frozenSeconds)).formatted(.time(pattern: .minuteSecond))
            Text(state.isOvertime ? "+\(frozen)" : frozen)
        case .overtime:
            if let goalDate = state.goalDate {
                Text("+\(Text(goalDate, style: .timer))")
            } else {
                Text(state.effectiveStart, style: .timer)
            }
        case .focusing:
            // `.timer` counts down to the goal and then keeps counting up past it, so the
            // display stays alive even if the app isn't around to switch to overtime.
            if let goalDate = state.goalDate {
                Text(goalDate, style: .timer)
            } else {
                Text(state.effectiveStart, style: .timer)
            }
        }
    }
}
