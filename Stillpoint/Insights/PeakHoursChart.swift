import Charts
import SwiftUI

/// When in the day focus actually happens.
struct PeakHoursChart: View {
    var hours: [HourTotal]
    var palette: OrbPalette

    var body: some View {
        let peak = hours.max { $0.minutes < $1.minutes }

        VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
            VStack(alignment: .leading, spacing: Theme.Spacing.hairline) {
                Text("Through the day")
                    .font(.sectionTitle)
                if let peak, peak.minutes > 0 {
                    Text("Most focus happens around \(Self.label(for: peak.hour))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Chart(hours) { hour in
                BarMark(
                    x: .value("Hour", hour.hour),
                    y: .value("Minutes", hour.minutes),
                    width: .fixed(8)
                )
                .foregroundStyle(hour.hour == peak?.hour ? palette.accent : palette.rim.mix(with: .white, by: 0.15))
                .cornerRadius(3)
            }
            .chartXScale(domain: -0.5...23.5)
            .chartXAxis {
                AxisMarks(values: [0, 6, 12, 18]) { value in
                    AxisValueLabel {
                        if let hour = value.as(Int.self) {
                            Text(Self.label(for: hour))
                        }
                    }
                }
            }
            .chartYAxis(.hidden)
            .frame(height: 120)
        }
    }

    static func label(for hour: Int) -> String {
        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: .now) ?? .now
        return date.formatted(.dateTime.hour())
    }
}
