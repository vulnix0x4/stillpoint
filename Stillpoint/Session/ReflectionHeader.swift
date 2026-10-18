import SwiftUI

/// The headline of a reflection: a glowing orb, the time focused, and what happened.
struct ReflectionHeader: View {
    var focused: TimeInterval
    var planned: TimeInterval?
    var reachedGoal: Bool
    var longestCalm: TimeInterval
    var thoughtCount: Int
    var palette: OrbPalette

    var body: some View {
        VStack(spacing: Theme.Spacing.medium) {
            LivingOrb(palette: palette, turbulence: 0.15, energy: reachedGoal ? 0.45 : 0.15)
                .frame(width: 150, height: 150)

            Text(title)
                .font(.display)
                .multilineTextAlignment(.center)

            Text(TimeText.short(focused))
                .font(.system(.largeTitle, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.tint)
                .accessibilityLabel("\(TimeText.spoken(focused)) focused")

            Text(details)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private var title: String {
        if focused < 60 { return "A brief visit" }
        if planned == nil { return "Flow, well held" }
        return reachedGoal ? "Well held" : "Session ended"
    }

    private var details: String {
        var parts: [String] = []
        if let planned {
            parts.append("Planned \(TimeText.short(planned))")
        }
        if longestCalm >= 60 {
            parts.append("Longest calm stretch \(TimeText.short(longestCalm))")
        }
        if thoughtCount > 0 {
            parts.append(thoughtCount == 1 ? "1 thought parked" : "\(thoughtCount) thoughts parked")
        }
        if focused < 60 {
            parts.append("Under a minute, so you might discard this one")
        }
        return parts.joined(separator: " · ")
    }
}
