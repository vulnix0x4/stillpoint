import AppIntents
import SwiftData
import SwiftUI

@main
struct StillpointApp: App {
    private let container: ModelContainer
    @State private var sound: SoundscapeEngine
    @State private var engine: SessionEngine

    init() {
        let container = ModelContainerFactory.make()
        let sound = SoundscapeEngine()
        let engine = SessionEngine(modelContext: container.mainContext, sound: sound)
        self.container = container
        _sound = State(initialValue: sound)
        _engine = State(initialValue: engine)

        AppDependencyManager.shared.add(dependency: engine)
        LaunchArguments.apply(to: container.mainContext)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(engine)
                .environment(sound)
                .preferredColorScheme(.dark)
                .task(restore)
        }
        .modelContainer(container)
    }

    private func restore() async {
        engine.restoreIfNeeded()
        WidgetSync.refresh(using: container.mainContext)
    }
}
