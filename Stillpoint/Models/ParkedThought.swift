import Foundation
import SwiftData

/// A stray thought captured mid-session so it can be dealt with later instead of now.
@Model
final class ParkedThought {
    var id: UUID = UUID()
    var text: String = ""
    var createdAt: Date = Date.now
    var isDone: Bool = false
    var completedAt: Date?
    var session: FocusSession?

    init(text: String, createdAt: Date = .now, session: FocusSession? = nil) {
        self.text = text
        self.createdAt = createdAt
        self.session = session
    }

    func toggleDone(at date: Date = .now) {
        isDone.toggle()
        completedAt = isDone ? date : nil
    }
}
