import SwiftUI
import AuthenticationServices

struct AuthChoiceView: View {
    @StateObject private var appleVM = AuthViewModel()
    @EnvironmentObject private var auth: SupabaseAuthManager

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = true
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Spacer(minLength: 40)

                    Image(systemName: "person.crop.circle")
                        .font(.system(size: 60))
                        .symbolRenderingMode(.hierarchical)

                    Text("Willkommen zurück!")
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

                    // ✅ Native Apple Button → Supabase
                    SignInWithAppleButton(
                        .signIn,
                        onRequest: appleVM.handleSignInWithAppleRequest,
                        onCompletion: { result in
                            Task {
                                do {
                                    try await appleVM.handleSignInWithAppleCompletion(result, authManager: auth)
                                } catch {
                                    errorMessage = "Anmeldung fehlgeschlagen: \(error.localizedDescription)"
                                }
                            }
                        }
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

                    Button {
                        hasCompletedOnboarding = false
                    } label: {
                        Text("Registrieren")
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
}
