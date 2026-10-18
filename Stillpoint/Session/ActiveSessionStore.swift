import Foundation

/// Persists the in-flight session so it survives the app being killed in the background.
struct ActiveSessionStore {
    private static let key = "activeSession.v1"
    var defaults: UserDefaults = .standard

    func save(_ session: PersistedSession) {
        guard let data = try? JSONEncoder().encode(session) else { return }
        defaults.set(data, forKey: Self.key)
    }

    func load() -> PersistedSession? {
        guard let data = defaults.data(forKey: Self.key) else { return nil }
        return try? JSONDecoder().decode(PersistedSession.self, from: data)
    }

    func clear() {
        defaults.removeObject(forKey: Self.key)
    }
}
