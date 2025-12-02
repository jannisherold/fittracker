import SwiftUI
import AuthenticationServices

struct OnboardingSignInView: View {
    @StateObject private var authViewModel = AuthViewModel()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false

    @State private var errorMessage: String?
    
    @State private var animate: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer(minLength: 40)

                Image(systemName: "person.crop.circle.badge.checkmark")
                    .font(.system(size: 60))
                    .symbolRenderingMode(.hierarchical)
                    .opacity(animate ? 1.0 : 0.0)
                    .scaleEffect(animate ? 1.0 : 0.8)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7), value: animate)

                Text("Mit Apple anmelden")
                    .font(.title)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .opacity(animate ? 1.0 : 0.0)
                    .animation(.easeOut.delay(0.1), value: animate)

                Text("Du nutzt diese App ausschließlich mit deinem Apple-Konto. So können deine Trainingsdaten optional über iCloud synchronisiert werden und du bist bereit für das zukünftige Freemium-Abomodell.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .opacity(animate ? 1.0 : 0.0)
                    .animation(.easeOut.delay(0.15), value: animate)
                
                Spacer()

                // MARK: - Sign in with Apple Button
                SignInWithAppleButton(
                    .continue,
                    onRequest: authViewModel.handleSignInWithAppleRequest,
                    onCompletion: handleCompletion
                )
                .signInWithAppleButtonStyle(.black)
                .frame(height: 50)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .padding(.horizontal, 32)
                .opacity(animate ? 1.0 : 0.0)
                .offset(y: animate ? 0 : 10)
                .animation(.easeOut.delay(0.2), value: animate)

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                VStack(spacing: 8) {
                    Text("Mit der Anmeldung akzeptierst du unsere AGB und Datenschutzerklärung.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    Text("Alle rechtlichen Informationen findest du später jederzeit in den Einstellungen unter „Rechtliches“.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal)

                //Spacer(minLength: 40)
            }
            .onAppear {
                animate = true
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Helpers

    private func handleCompletion(_ result: Result<ASAuthorization, Error>) {
        authViewModel.handleSignInWithAppleCompletion(result)

        switch result {
        case .success:
            // ✅ Onboarding als abgeschlossen markieren → AppStartView schaltet auf RootTabView um
            hasCompletedOnboarding = true

        case .failure(let error):
            errorMessage = "Die Anmeldung mit Apple ist fehlgeschlagen. Bitte versuche es erneut.\n(\(error.localizedDescription))"
        }
    }
}
