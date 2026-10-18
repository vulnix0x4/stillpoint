import SwiftUI
import WidgetKit

struct TodaySmallView: View {
    var snapshot: WidgetSnapshot
    var palette: OrbPalette

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top) {
                GoalRing(progress: snapshot.goalProgress, palette: palette, lineWidth: 6)
                    .frame(width: 64, height: 64)
                Spacer()
                if snapshot.streakDays > 0 {
                    Label("\(snapshot.streakDays)", systemImage: "flame.fill")
                        .font(.caption)
                        .bold()
                        .foregroundStyle(palette.accent)
                }
            }
            Spacer(minLength: 0)
            Text("\(snapshot.todayMinutes) min")
                .font(.system(.title2, design: .rounded))
                .bold()
                .monospacedDigit()
                .foregroundStyle(.white)
            Text("of \(snapshot.goalMinutes) today")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))
        }
    }
}
