import SwiftUI

/// Quarter-hour tick marks for the duration dial.
struct DialTicks: View {
    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) / 2
            for index in 0..<24 {
                let isMajor = index % 6 == 0
                let isMinor = index % 2 == 0
                let length: Double = isMajor ? 9 : (isMinor ? 5 : 3)
                let angle = Double(index) / 24 * 2 * .pi - .pi / 2
                let outer = CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
                let inner = CGPoint(x: center.x + cos(angle) * (radius - length), y: center.y + sin(angle) * (radius - length))
                var path = Path()
                path.move(to: inner)
                path.addLine(to: outer)
                context.stroke(
                    path,
                    with: .color(.white.opacity(isMajor ? 0.35 : 0.14)),
                    style: StrokeStyle(lineWidth: isMajor ? 2 : 1.2, lineCap: .round)
                )
            }
        }
        .accessibilityHidden(true)
    }
}
