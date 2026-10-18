import ActivityKit
import SwiftUI
import WidgetKit

struct FocusLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FocusActivityAttributes.self) { context in
            FocusLockScreenView(attributes: context.attributes, state: context.state)
                .activityBackgroundTint(Color(red: 0.035, green: 0.039, blue: 0.063).opacity(0.92))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            let palette = OrbPalette.named(context.attributes.paletteName)

            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    MiniOrb(palette: palette)
                        .frame(width: 40, height: 40)
                        .padding(.leading, 4)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    SessionCountdown(state: context.state)
                        .font(.system(.title2, design: .rounded))
                        .monospacedDigit()
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 110, alignment: .trailing)
                        .foregroundStyle(palette.accent)
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 2) {
                        Text(context.attributes.intention.isEmpty ? "Focusing" : context.attributes.intention)
                            .font(.system(.headline, design: .serif))
                            .lineLimit(1)
                        Text(context.state.phase == .paused ? "Paused" : context.state.depthTitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    SessionProgressBar(attributes: context.attributes, state: context.state, palette: palette)
                        .padding(.horizontal, 8)
                        .padding(.top, 4)
                }
            } compactLeading: {
                MiniOrb(palette: palette, glow: false)
                    .frame(width: 20, height: 20)
            } compactTrailing: {
                SessionCountdown(state: context.state)
                    .monospacedDigit()
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 52)
                    .foregroundStyle(palette.accent)
            } minimal: {
                MiniOrb(palette: palette, glow: false)
                    .frame(width: 20, height: 20)
            }
            .keylineTint(palette.accent)
        }
    }
}

#Preview("Lock Screen", as: .content, using: FocusActivityAttributes(intention: "Draft the introduction", plannedDuration: 1_500, paletteName: "ember")) {
    FocusLiveActivity()
} contentStates: {
    FocusActivityAttributes.ContentState(phase: .focusing, goalDate: .now.addingTimeInterval(900), effectiveStart: .now.addingTimeInterval(-600), frozenSeconds: 900, depthTitle: "Focused")
    FocusActivityAttributes.ContentState(phase: .paused, goalDate: nil, effectiveStart: .now.addingTimeInterval(-600), frozenSeconds: 900, depthTitle: "Focused")
}
