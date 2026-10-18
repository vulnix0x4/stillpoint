import SwiftUI

/// The animated heart of the session screen: orb, progress ring, time and depth.
struct LiveSessionDisplay: View {
    var palette: OrbPalette
    var parkedCount: Int

    @Environment(SessionEngine.self) private var engine
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: reduceMotion ? 0.5 : 1 / 30)) { context in
            let frame = engine.frame(at: context.date)
            let orbTime = context.date.timeIntervalSince(engine.clock?.startedAt ?? context.date) * (reduceMotion ? 0.12 : 1)

            VStack(spacing: Theme.Spacing.large) {
                ZStack {
                    ProgressRing(progress: frame.progress, palette: palette, isOpenEnded: frame.isOpenEnded, isComplete: frame.goalReached)
                    RippleRing(trigger: parkedCount, color: palette.core)
                        .padding(22)
                    OrbRenderer(palette: palette, time: orbTime, turbulence: frame.turbulence, energy: frame.energy)
                        .padding(22)
                        .opacity(frame.isPaused ? 0.5 : 1)
                    SessionTimeLabel(frame: frame)
                }
                .aspectRatio(1, contentMode: .fit)
                .frame(maxWidth: 380)

                DepthIndicator(depth: frame.depth, isPaused: frame.isPaused, palette: palette)
            }
        }
    }
}
