import Foundation
import Combine

@MainActor
final class SyncManager: ObservableObject {

    private unowned let store: Store
    private unowned let auth: SupabaseAuthManager

    private var cancellables = Set<AnyCancellable>()
    private var pushTask: Task<Void, Never>?

    init(store: Store, auth: SupabaseAuthManager) {
        self.store = store
        self.auth = auth

        // Wenn Session kommt/weggeht: reagieren
        auth.$session
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                Task { await self?.handleSessionChanged() }
            }
            .store(in: &cancellables)

        // Optional: Änderungen lokal -> später pushen (debounced)
        store.$trainings
            .dropFirst()
            .sink { [weak self] _ in self?.schedulePush() }
            .store(in: &cancellables)

        store.$bodyweightEntries
            .dropFirst()
            .sink { [weak self] _ in self?.schedulePush() }
            .store(in: &cancellables)
    }

    /// App wurde aktiv (Foreground) -> pull & push
    func appDidBecomeActive() {
        Task { await syncNow() }
    }

    private func handleSessionChanged() async {
        if auth.isLoggedIn {
            await syncNow()
        } else {
            // Logout: lokal alles löschen (wie von dir gewünscht)
            store.deleteAllData()
        }
    }

    /// Pull von Supabase -> lokal setzen; danach Push lokaler Zustand (damit "erstes Gerät" auch hochlädt)
    /// Pull von Supabase -> lokal setzen; danach Push lokaler Zustand
    func syncNow() async {
        guard let userId = auth.session?.user.id.uuidString else { return }

        // 1) Pull
        do {
            if let remote = try await SupabaseUserDataService.shared.fetchUserData(userId: userId) {
                store.trainings = remote.trainings ?? []
                store.bodyweightEntries = remote.bodyweight ?? []
            } else {
                // Noch keine Row -> initial anlegen (mit lokalem Stand)
                try await SupabaseUserDataService.shared.upsertUserData(
                    userId: userId,
                    trainings: store.trainings,
                    bodyweight: store.bodyweightEntries
                )
            }
        } catch {
            // ✅ Nicht ignorieren – sonst merkst du nie, dass Pull kaputt ist.
            print("❌ syncNow: Pull fehlgeschlagen:", error)
            return
        }

        // 2) Push (best effort) nur wenn Pull ok war
        do {
            try await SupabaseUserDataService.shared.upsertUserData(
                userId: userId,
                trainings: store.trainings,
                bodyweight: store.bodyweightEntries
            )
        } catch {
            print("⚠️ syncNow: Push fehlgeschlagen:", error)
        }
    }



    /// Debounced Push nach lokalen Änderungen
    private func schedulePush() {
        guard auth.isLoggedIn else { return }

        pushTask?.cancel()
        pushTask = Task { [weak self] in
            // Debounce 1.2s
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            await self?.pushOnly()
        }
    }

    private func pushOnly() async {
        guard let userId = auth.session?.user.id.uuidString else { return }
        do {
            try await SupabaseUserDataService.shared.upsertUserData(
                userId: userId,
                trainings: store.trainings,
                bodyweight: store.bodyweightEntries
            )
        } catch {
            // offline / Fehler -> ignorieren
        }
    }
}
