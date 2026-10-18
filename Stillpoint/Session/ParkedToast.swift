import SwiftUI

/// Brief confirmation that a thought was parked.
struct ParkedToast: View {
    var body: some View {
        Label("Parked. Back to it.", systemImage: "checkmark.circle.fill")
            .font(.subheadline)
            .bold()
            .padding(.horizontal, Theme.Spacing.medium)
            .padding(.vertical, Theme.Spacing.small)
            .glassEffect(.regular, in: .capsule)
            .accessibilityAddTraits(.isStaticText)
            .onAppear {
                AccessibilityNotification.Announcement("Thought parked").post()
            }
    }
}
