import SwiftUI

/// Entscheidet, ob Onboarding oder die eigentliche App angezeigt wird.
struct AppStartView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                RootTabView()
            } else {
                OnboardingView()
            }
        }
    }
}

#Preview {
    AppStartView()
        .environmentObject(Store())
}
