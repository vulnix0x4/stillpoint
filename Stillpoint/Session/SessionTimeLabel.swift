import SwiftUI

/// The time, written on the orb's bright core.
struct SessionTimeLabel: View {
    var frame: SessionFrame

    @ScaledMetric(relativeTo: .largeTitle) private var size = 58.0

    var body: some View {
        VStack(spacing: Theme.Spacing.hairline) {
            Text(primary)
                .font(.system(size: size, weight: .light, design: .rounded))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Text(caption)
                .font(.footnote)
                .bold()
                .textCase(.uppercase)
                .kerning(1.5)
        }
        .foregroundStyle(frame.isPaused ? Color.white : Theme.ink)
        // Already very large; beyond this it would outgrow the orb.
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .padding(.horizontal, Theme.Spacing.xLarge * 1.5)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spokenDescription)
        .accessibilityAddTraits(.updatesFrequently)
    }

    private var isOvertime: Bool {
        frame.goalReached && !frame.isOpenEnded
    }

    private var primary: String {
        if isOvertime {
            return "+" + TimeText.clock(frame.overtime)
        }
        if let remaining = frame.remaining {
            return TimeText.clock(remaining.rounded(.up))
        }
        return TimeText.clock(frame.elapsed)
    }

    private var caption: String {
        if frame.isPaused { return "Paused" }
        if isOvertime || frame.isOpenEnded { return "In flow" }
        return "Remaining"
    }

    private var spokenDescription: String {
        if isOvertime {
            return "Goal reached. \(TimeText.spoken(frame.overtime)) beyond it."
        }
        if let remaining = frame.remaining {
            return "\(TimeText.spoken(remaining.rounded(.up))) remaining"
        }
        return "\(TimeText.spoken(frame.elapsed)) in flow"
    }
}
