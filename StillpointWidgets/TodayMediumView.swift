import SwiftUI
import WidgetKit

struct TodayMediumView: View {
    var snapshot: WidgetSnapshot
    var palette: OrbPalette

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                GoalRing(progress: snapshot.goalProgress, palette: palette, lineWidth: 6)
                    .frame(width: 62, height: 62)
                Spacer(minLength: 0)
                Text("\(snapshot.todayMinutes) min")
                    .font(.system(.title2, design: .rounded))
                    .bold()
                    .monospacedDigit()
                Text("of \(snapshot.goalMinutes) · \(snapshot.sessionsToday) sessions")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Last 7 days")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                    Spacer()
                    if snapshot.streakDays > 0 {
                        Label("\(snapshot.streakDays) days", systemImage: "flame.fill")
                            .font(.caption)
                            .bold()
                            .foregroundStyle(palette.accent)
                    }
                }
                WeekBars(minutes: snapshot.lastSevenDays, goal: snapshot.goalMinutes, palette: palette)
            }
        }
        .foregroundStyle(.white)
    }
}
