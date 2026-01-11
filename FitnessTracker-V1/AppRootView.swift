import SwiftUI

struct AppRootView: View {
    @EnvironmentObject private var auth: SupabaseAuthManager

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @AppStorage("hasCreatedAccount") private var hasCreatedAccount: Bool = false
    @AppStorage("hasFinalizedRegistration") private var hasFinalizedRegistration: Bool = false

    var body: some View {
        if auth.isLoggedIn {
            // ✅ Angemeldet -> Registrierung finalisieren ODER Tabbar (Tabs haben ihre eigenen NavigationStacks)
            if hasFinalizedRegistration {
                RootTabView()
            } else {
                NavigationStack {
                    FinalizeRegistrationView()
                }
            }
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
