import SwiftUI

/// Sound control and a reminder of the plan.
struct SessionTopBar: View {
    var plan: SessionPlan
    var openMixer: () -> Void

    var body: some View {
        HStack {
            Button("Soundscape", systemImage: "speaker.wave.2", action: openMixer)
                .labelStyle(.iconOnly)
                .font(.title3)
                .frame(width: 48, height: 48)
                .glassEffect(.regular.interactive(), in: .circle)
                .buttonStyle(.plain)

            Spacer()

            Label(planDescription, systemImage: plan.plannedMinutes == nil ? "infinity" : "timer")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.horizontal, Theme.Spacing.medium)
                .padding(.vertical, Theme.Spacing.small)
                .glassEffect(.regular, in: .capsule)
        }
    }

    private var planDescription: String {
        if let minutes = plan.plannedMinutes {
            "\(minutes) min session"
        } else {
            "Open flow"
        }
    }
}
