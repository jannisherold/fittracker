import SwiftUI

@main
struct FitnessTrackerV1App: App {
    @Environment(\.scenePhase) private var scenePhase

    @StateObject private var store: Store
    @StateObject private var auth: SupabaseAuthManager
    @StateObject private var sync: SyncManager

    init() {
        let s = Store()
        let a = SupabaseAuthManager()
        _store = StateObject(wrappedValue: s)
        _auth = StateObject(wrappedValue: a)
        _sync = StateObject(wrappedValue: SyncManager(store: s, auth: a))
    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environmentObject(store)
                .environmentObject(auth)
                .environmentObject(sync)
        }
        .onChange(of: scenePhase) { _, newValue in
            if newValue == .active {
                sync.appDidBecomeActive()
            }
        }
    }
}
