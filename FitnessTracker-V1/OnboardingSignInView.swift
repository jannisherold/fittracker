import SwiftUI
import AuthenticationServices

struct OnboardingSignInView: View {
    @StateObject private var authViewModel = AuthViewModel()
    @EnvironmentObject private var auth: SupabaseAuthManager

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // ... dein UI ...

                SignInWithAppleButton(
                    .continue,
                    onRequest: authViewModel.handleSignInWithAppleRequest,
                    onCompletion: { result in
                        Task {
                            do {
                                try await authViewModel.handleSignInWithAppleCompletion(result, authManager: auth)
                                hasCompletedOnboarding = true
                            } catch {
                                errorMessage = "Apple Login fehlgeschlagen: \(error.localizedDescription)"
                            }
                        }
                    }
                )
                .signInWithAppleButtonStyle(.black)
                .frame(height: 50)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .padding(.horizontal, 32)

                if let errorMessage {
                    Text(errorMessage).foregroundColor(.red).font(.footnote)
                }
            }
        }
    }
}
