import SwiftUI

/// Hosts the stages of a session in one full-screen space, cross-fading between them.
struct SessionContainerView: View {
    @Environment(SessionEngine.self) private var engine
    @AppStorage(PreferenceKey.palette) private var paletteName = OrbPalette.ember.rawValue

    var body: some View {
        let palette = OrbPalette.named(paletteName)

        ZStack {
            AmbientBackground(palette: palette, intensity: engine.stage == .focusing ? 1.25 : 1)

            switch engine.stage {
            case .arriving:
                ArrivalBreathingView(
                    pattern: engine.plan.breathPattern,
                    intention: engine.plan.intention,
                    palette: palette,
                    onFinish: engine.finishArrival,
                    onCancel: engine.cancelArrival
                )
                .transition(.opacity)
            case .focusing:
                FocusSessionView(palette: palette)
                    .transition(.opacity)
            case .reflecting:
                ReflectionView(palette: palette)
                    .transition(.opacity)
            case .idle:
                Color.clear
            }
        }
        .animation(Theme.Motion.stageChange, value: engine.stage)
        .preferredColorScheme(.dark)
    }
}
