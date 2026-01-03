import Foundation
import Combine

/// Offline-first Sync:
/// - UI liest immer aus lokalem JSON Store
/// - lokale Änderungen markieren einen dirty Zustand
/// - wenn dirty -> nur PUSH (niemals Pull überschreibt)
/// - wenn clean -> Pull ist erlaubt
@MainActor
final class SyncManager: ObservableObject {
    private unowned let store: Store
    private unowned let auth: SupabaseAuthManager

    private var cancellables = Set<AnyCancellable>()
    private var pushTask: Task<Void, Never>?

    @Published private(set) var isSyncing: Bool = false

    init(store: Store, auth: SupabaseAuthManager) {
        self.store = store
        self.auth = auth

        // Wenn Session kommt: optional initial sync
        auth.$session
            .receive(on: DispatchQueue.main)
            .sink { [weak self] session in
                guard let self else { return }
                if session != nil {
                    print("🔄 SyncManager: session available -> syncNow()")
                    Task { await self.syncNow(reason: "sessionChanged") }
                } else {
                    // KEIN auto wipe mehr (sonst Datenverlust bei Offline/Restore-Glitches)
                    print("🔄 SyncManager: session nil (no auto local wipe)")
                }
            }
            .store(in: &cancellables)

        // Lokale Änderungen -> dirty + debounced push
        store.$trainings.dropFirst().sink { [weak self] _ in
            self?.markDirtyAndSchedulePush(reason: "trainingsChanged")
        }.store(in: &cancellables)

        store.$bodyweightEntries.dropFirst().sink { [weak self] _ in
            self?.markDirtyAndSchedulePush(reason: "bodyweightChanged")
        }.store(in: &cancellables)
    }

    /// App wurde aktiv (Foreground)
    func appDidBecomeActive() {
        Task { await syncNow(reason: "appActive") }
    }

    // MARK: - Dirty state

    private func markDirtyAndSchedulePush(reason: String) {
        guard auth.isLoggedIn else {
            print("📝 markDirty ignored (not logged in) reason=\(reason)")
            return
        }

        var state = SyncStateStore.load()
        if !state.isDirty {
            print("📝 markDirty=true reason=\(reason)")
        }
        state.isDirty = true
        SyncStateStore.save(state)

        schedulePush()
    }

    private func schedulePush() {
        guard auth.isLoggedIn else { return }

        pushTask?.cancel()
        pushTask = Task { [weak self] in
            // Debounce ~1.2s
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            await self?.pushOnly(reason: "debounced")
        }
    }

    // MARK: - Sync

    func syncNow(reason: String) async {
        guard let userId = auth.session?.user.id.uuidString else {
            print("🔄 syncNow aborted (no userId) reason=\(reason)")
            return
        }

        isSyncing = true
        defer { isSyncing = false }

        let state = SyncStateStore.load()
        print("🔄 syncNow start reason=\(reason) dirty=\(state.isDirty)")

        if state.isDirty {
            // Lokale Änderungen haben Vorrang: nur push
            await pushOnly(reason: "syncNow(dirty)")
            return
        }

        // Clean: Pull ist erlaubt
        do {
            if let remote = try await SupabaseUserDataService.shared.fetchUserData(userId: userId) {
                print("⬇️ Pull OK (remote row exists)")
                store.trainings = remote.trainings ?? []
                store.bodyweightEntries = remote.bodyweight ?? []
            } else {
                print("⬇️ Pull OK (no row) -> create initial row")
                try await SupabaseUserDataService.shared.upsertUserData(
                    userId: userId,
                    trainings: store.trainings,
                    bodyweight: store.bodyweightEntries
                )
            }
        } catch {
            // Offline/Fehler: UI bleibt lokal stabil
            print("⚠️ syncNow: Pull failed (ignored) error=\(error)")
        }
    }

    private func pushOnly(reason: String) async {
        guard let userId = auth.session?.user.id.uuidString else {
            print("⬆️ pushOnly aborted (no userId) reason=\(reason)")
            return
        }

        do {
            print("⬆️ Push start reason=\(reason) trainings=\(store.trainings.count) bw=\(store.bodyweightEntries.count)")
            try await SupabaseUserDataService.shared.upsertUserData(
                userId: userId,
                trainings: store.trainings,
                bodyweight: store.bodyweightEntries
            )

            var state = SyncStateStore.load()
            state.isDirty = false
            state.lastSuccessfulSyncAt = Date()
            SyncStateStore.save(state)
            print("⬆️ Push OK -> dirty=false")
        } catch {
            // Offline/Fehler: dirty bleibt true
            print("⚠️ Push failed (will retry later) error=\(error)")
        }
    }

    /// Für Logout: MUSS erfolgreich sein, sonst darf lokal nichts gelöscht werden.
    func flushOrThrow() async throws {
        guard let userId = auth.session?.user.id.uuidString else { return }

        let state = SyncStateStore.load()
        guard state.isDirty else {
            print("✅ flushOrThrow: nothing to do (clean)")
            return
        }

        print("✅ flushOrThrow: pushing before logout...")
        try await SupabaseUserDataService.shared.upsertUserData(
            userId: userId,
            trainings: store.trainings,
            bodyweight: store.bodyweightEntries
        )

        var newState = state
        newState.isDirty = false
        newState.lastSuccessfulSyncAt = Date()
        SyncStateStore.save(newState)
        print("✅ flushOrThrow: push ok -> clean")
    }
}
