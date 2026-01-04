import Foundation
import Combine

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

        auth.$session
            .receive(on: DispatchQueue.main)
            .sink { [weak self] session in
                guard let self else { return }
                if session != nil {
                    print("🔄 SyncManager: session available -> syncNow()")
                    Task { await self.syncNow(reason: "sessionChanged") }
                } else {
                    print("🔄 SyncManager: session nil (no auto local wipe)")
                }
            }
            .store(in: &cancellables)

        store.$trainings.dropFirst().sink { [weak self] _ in
            self?.markDirtyAndSchedulePush(reason: "trainingsChanged")
        }.store(in: &cancellables)

        store.$bodyweightEntries.dropFirst().sink { [weak self] _ in
            self?.markDirtyAndSchedulePush(reason: "bodyweightChanged")
        }.store(in: &cancellables)

        // ✅ Neu: Rest timer settings
        store.$restTimerEnabled.dropFirst().sink { [weak self] _ in
            self?.markDirtyAndSchedulePush(reason: "restTimerEnabledChanged")
        }.store(in: &cancellables)

        store.$restTimerSeconds.dropFirst().sink { [weak self] _ in
            self?.markDirtyAndSchedulePush(reason: "restTimerSecondsChanged")
        }.store(in: &cancellables)
    }

    func appDidBecomeActive() {
        Task { await syncNow(reason: "appActive") }
    }

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
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            await self?.pushOnly(reason: "debounced")
        }
    }

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
            await pushOnly(reason: "syncNow(dirty)")
            return
        }

        do {
            if let remote = try await SupabaseUserDataService.shared.fetchUserData(userId: userId) {
                print("⬇️ Pull OK (remote row exists)")
                store.trainings = remote.trainings ?? []
                store.bodyweightEntries = remote.bodyweight ?? []

                if let enabled = remote.rest_timer_enabled {
                    store.restTimerEnabled = enabled
                }
                if let secs = remote.rest_timer_seconds {
                    store.restTimerSeconds = secs
                }

                print("⬇️ Pull restTimer: enabled=\(store.restTimerEnabled) seconds=\(store.restTimerSeconds)")
            } else {
                print("⬇️ Pull OK (no row) -> create initial row")
                try await SupabaseUserDataService.shared.upsertUserData(
                    userId: userId,
                    trainings: store.trainings,
                    bodyweight: store.bodyweightEntries,
                    restTimerEnabled: store.restTimerEnabled,
                    restTimerSeconds: store.restTimerSeconds
                )
            }
        } catch {
            print("⚠️ syncNow: Pull failed (ignored) error=\(error)")
        }
    }

    private func pushOnly(reason: String) async {
        guard let userId = auth.session?.user.id.uuidString else {
            print("⬆️ pushOnly aborted (no userId) reason=\(reason)")
            return
        }

        do {
            print("⬆️ Push start reason=\(reason) trainings=\(store.trainings.count) bw=\(store.bodyweightEntries.count) restEnabled=\(store.restTimerEnabled) restSecs=\(store.restTimerSeconds)")
            try await SupabaseUserDataService.shared.upsertUserData(
                userId: userId,
                trainings: store.trainings,
                bodyweight: store.bodyweightEntries,
                restTimerEnabled: store.restTimerEnabled,
                restTimerSeconds: store.restTimerSeconds
            )

            var state = SyncStateStore.load()
            state.isDirty = false
            state.lastSuccessfulSyncAt = Date()
            SyncStateStore.save(state)
            print("⬆️ Push OK -> dirty=false")
        } catch {
            print("⚠️ Push failed (will retry later) error=\(error)")
        }
    }

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
            bodyweight: store.bodyweightEntries,
            restTimerEnabled: store.restTimerEnabled,
            restTimerSeconds: store.restTimerSeconds
        )

        var newState = state
        newState.isDirty = false
        newState.lastSuccessfulSyncAt = Date()
        SyncStateStore.save(newState)
        print("✅ flushOrThrow: push ok -> clean")
    }
}
