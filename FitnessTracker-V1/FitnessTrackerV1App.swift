import SwiftUI

@main
struct FitnessTrackerV1App: App {
    @StateObject private var store = Store()
    @StateObject private var auth = SupabaseAuthManager()

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environmentObject(store)
                .environmentObject(auth)
        }
    }
}
