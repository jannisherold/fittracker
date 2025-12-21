import SwiftUI

struct AppRootView: View {
    @EnvironmentObject private var auth: SupabaseAuthManager
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false

    var body: some View {
        NavigationStack {
            Group {
                if auth.isLoggedIn {
                    SplashScreenView()
                } else if !hasCompletedOnboarding {
                    OnboardingView()
                } else {
                    OnboardingRegisterView()
                }
            }
        }
    }
}
