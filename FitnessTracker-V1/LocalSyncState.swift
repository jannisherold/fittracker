import Foundation

/// Kleiner Persistenz-State für Offline-First Sync.
/// - isDirty: es gibt lokale Änderungen, die noch nicht in Supabase sind
/// - lastSuccessfulSyncAt: Timestamp für Debug/Analytics
struct LocalSyncState: Codable {
    var isDirty: Bool = false
    var lastSuccessfulSyncAt: Date? = nil
}

enum SyncStateStore {
    private static let key = "localSyncState"

    static func load() -> LocalSyncState {
        guard let data = UserDefaults.standard.data(forKey: key),
              let state = try? JSONDecoder().decode(LocalSyncState.self, from: data)
        else {
            return LocalSyncState()
        }
        return state
    }

    static func save(_ state: LocalSyncState) {
        let data = try? JSONEncoder().encode(state)
        UserDefaults.standard.set(data, forKey: key)
    }

    static func reset() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
