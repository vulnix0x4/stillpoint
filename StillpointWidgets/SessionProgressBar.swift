import SwiftUI

/// A progress bar the system animates on its own between activity updates.
struct SessionProgressBar: View {
    var attributes: FocusActivityAttributes
    var state: FocusActivityAttributes.ContentState
    var palette: OrbPalette

    var body: some View {
        Group {
            if state.phase == .focusing, let goalDate = state.goalDate, goalDate > state.effectiveStart {
                ProgressView(timerInterval: state.effectiveStart...goalDate, countsDown: false) {
                    EmptyView()
                } currentValueLabel: {
                    EmptyView()
                }
            } else if state.phase == .paused, !state.isOvertime, let planned = attributes.plannedDuration, planned > 0 {
                ProgressView(value: max(0, min(1, 1 - state.frozenSeconds / planned)))
            } else {
                ProgressView(value: 1)
            }
        }
        .progressViewStyle(.linear)
        .tint(palette.accent)
        .labelsHidden()
    }
}
