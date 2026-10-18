import SwiftUI

/// Today's focus against the daily goal, as a thin luminous bar.
struct TodayProgress: View {
    var minutes: Int
    var goal: Int
    var sessions: Int
    var palette: OrbPalette

    private var fraction: Double {
        guard goal > 0 else { return 0 }
        return min(1, Double(minutes) / Double(goal))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.tight) {
            HStack(alignment: .firstTextBaseline) {
                Text("Today")
                    .font(.subheadline)
                    .bold()
                Spacer()
                Text("\(minutes) of \(goal) min · ^[\(sessions) session](inflect: true)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Capsule()
                .fill(Color.white.opacity(0.08))
                .frame(height: 6)
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(LinearGradient(colors: [palette.rim, palette.mid, palette.core], startPoint: .leading, endPoint: .trailing))
                        .scaleEffect(x: max(fraction, 0.001), anchor: .leading)
                        .shadow(color: palette.mid.opacity(0.6), radius: 6)
                }
                .clipShape(.capsule)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Today")
        .accessibilityValue("\(minutes) of \(goal) minutes, \(sessions) sessions")
    }
}
