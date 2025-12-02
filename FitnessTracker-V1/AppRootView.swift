import SwiftUI

struct AppRootView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false

    var body: some View {
        Group {
            // 1) Noch nie Onboarding gemacht → komplettes Onboarding
            if !hasCompletedOnboarding {
                OnboardingView()
            }
            // 2) Onboarding fertig + eingeloggt → Splash → Tabs
            else if isLoggedIn {
                SplashScreenView()
            }
            // 3) Onboarding fertig, aber ausgeloggt → Login / Neu registrieren
            else {
                AuthChoiceView()
            }
        }
    }
}
