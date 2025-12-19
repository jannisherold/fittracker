import SwiftUI

struct AppRootView: View {
    @EnvironmentObject private var auth: SupabaseAuthManager

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false

    var body: some View {
        Group {
            if !hasCompletedOnboarding {
                OnboardingView()
            } else if auth.isLoggedIn {
                SplashScreenView()
            } else {
                AuthChoiceView()
            }
        }
    }
}
