import Charts
import SwiftUI

/// Minutes per day against the daily goal.
struct DailyFocusChart: View {
    var records: [SessionRecord]
    var goalMinutes: Int
    var palette: OrbPalette

    @State private var range = ChartRange.week

    var body: some View {
        let days = StatsCalculator().dailyTotals(records, days: range.days, endingOn: .now)
        let total = days.reduce(0) { $0 + $1.minutes }
        let daysMeetingGoal = days.count { $0.minutes >= Double(goalMinutes) }

        VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: Theme.Spacing.hairline) {
                    Text("Focus time")
                        .font(.sectionTitle)
                    Text("\(TimeText.short(total * 60)) · goal met on \(daysMeetingGoal) of \(range.days) days")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            Picker("Range", selection: $range) {
                ForEach(ChartRange.allCases) { range in
                    Text(range.title).tag(range)
                }
            }
            .pickerStyle(.segmented)

            Chart {
                ForEach(days) { day in
                    BarMark(
                        x: .value("Day", day.date, unit: .day),
                        y: .value("Minutes", day.minutes)
                    )
                    .foregroundStyle(
                        day.minutes >= Double(goalMinutes)
                            ? AnyShapeStyle(LinearGradient(colors: [palette.mid, palette.core], startPoint: .bottom, endPoint: .top))
                            : AnyShapeStyle(LinearGradient(colors: [palette.rim, palette.mid], startPoint: .bottom, endPoint: .top))
                    )
                    .cornerRadius(range == .week ? 6 : 3)
                }
                RuleMark(y: .value("Goal", goalMinutes))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .foregroundStyle(.secondary)
                    .annotation(position: .top, alignment: .trailing, spacing: 2) {
                        Text("Goal")
                            .font(.caption)
                            .bold()
                            .padding(.horizontal, Theme.Spacing.tight)
                            .padding(.vertical, Theme.Spacing.hairline)
                            .background(Theme.canvas.opacity(0.85), in: .capsule)
                    }
            }
            .chartXAxis {
                if range == .week {
                    AxisMarks(values: .stride(by: .day)) {
                        AxisValueLabel(format: .dateTime.weekday(.narrow), centered: true)
                    }
                } else {
                    AxisMarks(values: .stride(by: .day, count: 7)) {
                        AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine().foregroundStyle(Theme.hairline)
                    AxisValueLabel {
                        if let minutes = value.as(Double.self) {
                            Text(TimeText.short(minutes * 60))
                        }
                    }
                }
            }
            .frame(height: 190)
            .animation(Theme.Motion.settle, value: range)
        }
    }
}
