import SwiftUI

struct AppRootView: View {
    @EnvironmentObject private var auth: SupabaseAuthManager

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @AppStorage("hasCreatedAccount") private var hasCreatedAccount: Bool = false

    var body: some View {
        Group {
            if auth.isLoggedIn {
                // ✅ Angemeldet -> Tabbar mit 3 Tabs
                RootTabView()
            } else if !hasCompletedOnboarding {
                // ✅ Neu: Onboarding zuerst
                OnboardingView()
            } else if !hasCreatedAccount {
                // ✅ Onboarding fertig, aber noch nie Account erstellt -> Register
                OnboardingRegisterView()
            } else {
                // ✅ Account existiert, aber abgemeldet -> Login
                LoginView()
            }
        }
    }
}
