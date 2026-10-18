import SwiftUI

/// A ring around the orb that sets the session length. Drag the knob around, or use the
/// VoiceOver adjustable action. One full turn is two hours, in five-minute steps.
struct DurationDial: View {
    @Binding var minutes: Int
    var isFlow: Bool
    var palette: OrbPalette

    static let range = 5...120
    static let step = 5
    private static let lineWidth: Double = 10

    @State private var size = CGSize.zero

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.07), lineWidth: Self.lineWidth)

            DialTicks()
                .padding(Self.lineWidth * 1.8)

            Circle()
                .trim(from: 0, to: isFlow ? 1 : fraction)
                .stroke(
                    AngularGradient(colors: [palette.rim, palette.mid, palette.accent], center: .center),
                    style: StrokeStyle(lineWidth: Self.lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .opacity(isFlow ? 0.35 : 1)

            Circle()
                .fill(.white)
                .frame(width: 26, height: 26)
                .shadow(color: palette.accent.opacity(0.8), radius: 10)
                .offset(knobOffset)
                .opacity(isFlow ? 0 : 1)
        }
        .padding(Self.lineWidth / 2)
        .contentShape(.circle)
        .onGeometryChange(for: CGSize.self, of: \.size) { size = $0 }
        .gesture(dragGesture, isEnabled: !isFlow)
        .sensoryFeedback(.selection, trigger: minutes)
        .animation(Theme.Motion.quick, value: isFlow)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Session length")
        .accessibilityValue(isFlow ? "Open-ended flow" : "\(minutes) minutes")
        .accessibilityAdjustableAction(adjust)
    }

    private var fraction: Double {
        Double(minutes) / Double(Self.range.upperBound)
    }

    private var knobOffset: CGSize {
        let radius = max(0, min(size.width, size.height) / 2 - Self.lineWidth / 2 - Self.lineWidth / 2)
        let angle = fraction * 2 * .pi - .pi / 2
        return CGSize(width: cos(angle) * radius, height: sin(angle) * radius)
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                updateMinutes(for: value.location)
            }
    }

    private func updateMinutes(for location: CGPoint) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let dx = location.x - center.x
        let dy = location.y - center.y
        // Ignore touches right in the middle, where the angle is meaningless.
        guard hypot(dx, dy) > 30 else { return }

        var angle = atan2(dy, dx) + .pi / 2
        if angle < 0 { angle += 2 * .pi }
        let raw = angle / (2 * .pi) * Double(Self.range.upperBound)
        let stepped = Int((raw / Double(Self.step)).rounded()) * Self.step
        let clamped = min(Self.range.upperBound, max(Self.range.lowerBound, stepped))

        // Don't let a drag wrap from 120 straight round to 5, or back.
        if abs(clamped - minutes) > Self.range.upperBound / 2 { return }
        if clamped != minutes {
            minutes = clamped
        }
    }

    private func adjust(_ direction: AccessibilityAdjustmentDirection) {
        switch direction {
        case .increment: minutes = min(Self.range.upperBound, minutes + Self.step)
        case .decrement: minutes = max(Self.range.lowerBound, minutes - Self.step)
        @unknown default: break
        }
    }
}
