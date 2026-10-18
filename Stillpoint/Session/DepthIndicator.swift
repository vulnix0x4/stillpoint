import SwiftUI

/// Shows how settled the session is: settling in, focused, or deep.
struct DepthIndicator: View {
    var depth: FocusDepth
    var isPaused: Bool
    var palette: OrbPalette

    var body: some View {
        VStack(spacing: Theme.Spacing.tight) {
            HStack(spacing: Theme.Spacing.tight) {
                ForEach(FocusDepth.allCases, id: \.self) { level in
                    Capsule()
                        .fill(level <= depth && !isPaused ? palette.accent : Color.white.opacity(0.15))
                        .frame(width: level == depth ? 24 : 8, height: 8)
                }
            }
            Text(isPaused ? "Paused" : depth.title)
                .font(.headline)
                .contentTransition(.opacity)
            Text(isPaused ? "Take the break you need. The thread will be here." : depth.guidance)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .contentTransition(.opacity)
                .frame(minHeight: 40, alignment: .top)
        }
        .animation(Theme.Motion.settle, value: depth)
        .animation(Theme.Motion.settle, value: isPaused)
        .accessibilityElement(children: .combine)
    }
}
