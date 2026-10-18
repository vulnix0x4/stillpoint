import Foundation
import SwiftData

/// Builds the app's SwiftData container.
enum ModelContainerFactory {
    static func make(inMemory: Bool = false) -> ModelContainer {
        let schema = Schema([FocusSession.self, ParkedThought.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Stillpoint couldn't open its data store: \(error)")
        }
    }
}
