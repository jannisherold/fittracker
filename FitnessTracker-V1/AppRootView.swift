import SwiftUI

struct AppRootView: View {
    @EnvironmentObject private var auth: SupabaseAuthManager

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @AppStorage("hasCreatedAccount") private var hasCreatedAccount: Bool = false

    var body: some View {
        if auth.isLoggedIn {
            // ✅ Angemeldet -> Tabbar (Tabs haben ihre eigenen NavigationStacks)
            RootTabView()
        } else {
            // ✅ Abgemeldet -> eigener NavigationStack nur für Auth/Onboarding
            NavigationStack {
                Group {
                    if !hasCompletedOnboarding {
                        OnboardingView()
                    } else if !hasCreatedAccount {
                        OnboardingRegisterView()
                    } else {
                        LoginView()
                    }
                }
            }
        }
    }
}
