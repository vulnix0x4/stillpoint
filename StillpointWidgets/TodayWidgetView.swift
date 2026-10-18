import SwiftUI
import WidgetKit

struct TodayWidgetView: View {
    var entry: TodayEntry

    @Environment(\.widgetFamily) private var family

    var body: some View {
        let snapshot = entry.snapshot
        let palette = OrbPalette.named(snapshot.paletteName)

        Group {
            switch family {
            case .accessoryCircular:
                Gauge(value: snapshot.goalProgress) {
                    Image(systemName: "circle.circle")
                } currentValueLabel: {
                    Text(snapshot.todayMinutes, format: .number)
                }
                .gaugeStyle(.accessoryCircularCapacity)
                .widgetAccentable()
                .containerBackground(.clear, for: .widget)
            case .accessoryRectangular:
                VStack(alignment: .leading, spacing: 1) {
                    Text("Stillpoint")
                        .font(.headline)
                        .widgetAccentable()
                    Text("\(snapshot.todayMinutes) of \(snapshot.goalMinutes) min")
                    Text(snapshot.streakDays > 0 ? "\(snapshot.streakDays)-day streak" : "Start a streak today")
                        .foregroundStyle(.secondary)
                }
                .containerBackground(.clear, for: .widget)
            case .accessoryInline:
                Text("\(snapshot.todayMinutes) min focused today")
                    .containerBackground(.clear, for: .widget)
            case .systemMedium:
                TodayMediumView(snapshot: snapshot, palette: palette)
                    .containerBackground(for: .widget) { WidgetBackground(palette: palette) }
            default:
                TodaySmallView(snapshot: snapshot, palette: palette)
                    .containerBackground(for: .widget) { WidgetBackground(palette: palette) }
            }
        }
    }
}
