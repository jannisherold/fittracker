import SwiftUI
import AuthenticationServices

struct AuthChoiceView: View {
    @StateObject private var authViewModel = AuthViewModel()

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = true
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false

    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            
            ScrollView{
                VStack(spacing: 24) {
                    Spacer(minLength: 40)

                    Image(systemName: "person.crop.circle")
                        .font(.system(size: 60))
                        .symbolRenderingMode(.hierarchical)

                    Text("Willkommen zurück 👋")
                        .font(.title)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    Text("Melde dich mit deinem Apple-Account an oder starte eine neue Registrierung.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)

                    Spacer()

                    // MARK: - Login mit Apple
                    SignInWithAppleButton(
                        .signIn,
                        onRequest: authViewModel.handleSignInWithAppleRequest,
                        onCompletion: handleSignInCompletion
                    )
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .padding(.horizontal, 32)

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    // MARK: - Neu registrieren
                    Button {
                        // zurück in den Onboarding-Flow springen
                        hasCompletedOnboarding = false
                    } label: {
                        Text("Neu registrieren")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .padding(.horizontal, 32)

                    
                }
            }
            

        }
    }

    private func handleSignInCompletion(_ result: Result<ASAuthorization, Error>) {
        authViewModel.handleSignInWithAppleCompletion(result)

        switch result {
        case .success:
            // Nutzer wieder eingeloggt
            isLoggedIn = true
        case .failure(let error):
            errorMessage = "Die Anmeldung mit Apple ist fehlgeschlagen. Bitte versuche es erneut.\n(\(error.localizedDescription))"
        }
    }
}
