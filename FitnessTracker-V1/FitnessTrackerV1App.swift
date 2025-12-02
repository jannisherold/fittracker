import SwiftUI

@main
struct FitnessTrackerV1App: App {
    @StateObject private var store = Store()

    var body: some Scene {
        WindowGroup {
            //SplashScreenView()
            OnboardingView()
            //SignInTestView()
                .environmentObject(store)
        }
    }
}
