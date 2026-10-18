import SwiftUI

/// Seven small bars, today on the right.
struct WeekBars: View {
    var minutes: [Int]
    var goal: Int
    var palette: OrbPalette

    var body: some View {
        let ceiling = Double(max(goal, minutes.max() ?? 0, 1))

        HStack(alignment: .bottom, spacing: 6) {
            ForEach(Array(minutes.enumerated()), id: \.offset) { index, value in
                let isToday = index == minutes.count - 1
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: value >= goal ? [palette.mid, palette.core] : [palette.rim, palette.mid.opacity(0.8)],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(maxWidth: .infinity)
                    .frame(height: max(4, 70 * Double(value) / ceiling))
                    .opacity(isToday ? 1 : 0.75)
            }
        }
        .frame(maxHeight: .infinity, alignment: .bottom)
    }
}
