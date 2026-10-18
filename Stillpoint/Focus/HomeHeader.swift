import SwiftUI

/// Greeting, date and streak.
struct HomeHeader: View {
    var streak: Int
    var now: Date

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: Theme.Spacing.hairline) {
                Text(greeting)
                    .font(.display)
                Text(now, format: .dateTime.weekday(.wide).day().month(.wide))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if streak > 0 {
                Label {
                    Text(streak, format: .number)
                        .monospacedDigit()
                } icon: {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(.tint)
                }
                .font(.headline)
                .padding(.horizontal, Theme.Spacing.small)
                .padding(.vertical, Theme.Spacing.tight)
                .glassEffect(.regular, in: .capsule)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Streak: \(streak) days")
            }
        }
    }

    private var greeting: String {
        switch Calendar.current.component(.hour, from: now) {
        case 5..<12: "Good morning"
        case 12..<17: "Good afternoon"
        case 17..<22: "Good evening"
        default: "Quiet hours"
        }
    }
}
