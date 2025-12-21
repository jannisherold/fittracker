import SwiftUI
import AuthenticationServices

struct OnboardingRegisterView: View {
    @StateObject private var appleVM = AuthViewModel()
    @EnvironmentObject private var auth: SupabaseAuthManager

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false

    @State private var email: String = ""
    @State private var password: String = ""
    @State private var hasAcceptedLegal: Bool = false

    @State private var isLoading: Bool = false
    @State private var errorMessage: String?

    private var canCreateAccount: Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        password.count >= 6 &&
        hasAcceptedLegal &&
        !isLoading
    }

    var body: some View {
        // Wichtig: NavigationStack, damit der "Einloggen"-Link pushen kann.
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {

                    // Titel
                    Text("Registrieren")
                        .font(.title)
                        .fontWeight(.semibold)
                        .padding(.top, 24)
                    
                    Spacer(minLength: 24)
                    
                    // Sign up with Apple (wie gehabt)
                    SignInWithAppleButton(
                        .signUp,
                        onRequest: appleVM.handleSignInWithAppleRequest,
                        onCompletion: { result in
                            Task {
                                do {
                                    try await appleVM.handleSignInWithAppleCompletion(result, authManager: auth)
                                    // Wenn Apple-Login klappt, Onboarding abschließen:
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
                    .padding(.horizontal, 24)
                    
                    // Trennlinie "Oder"
                    HStack(spacing: 12) {
                        Rectangle().frame(height: 1).foregroundColor(.secondary.opacity(0.35))
                        Text("Oder")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        Rectangle().frame(height: 1).foregroundColor(.secondary.opacity(0.35))
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 6)

                    // E-Mail
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("E-Mail Adresse", text: $email)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .padding(14)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .padding(.horizontal, 24)

                    // Passwort
                    VStack(alignment: .leading, spacing: 8) {
                        SecureField("Passwort", text: $password)
                            .textContentType(.newPassword)
                            .padding(14)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                        Text("Lowercase, Uppercase Letters, digits ans symbols, 8 zeichen")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 24)

                  
                    // Neu: "Du hast bereits..." + Navigation zur Login View
                    

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }

                    /*
                    // AGB/Datenschutz – dezenter (kleineres Icon, weniger “Button-Look”)
                    Button {
                        hasAcceptedLegal.toggle()
                    } label: {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: hasAcceptedLegal ? "checkmark.square.fill" : "square")
                                .font(.system(size: 16, weight: .regular))
                                .foregroundStyle(
                                    hasAcceptedLegal
                                    ? AnyShapeStyle(Color.secondary.opacity(0.9))
                                    : AnyShapeStyle(Color.secondary.opacity(0.5))
                                )
                                .padding(.top, 2)

                            Text("Ich akzeptiere die AGBs und Datenschutzerklärung")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.leading)

                            Spacer()
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                        .background(.ultraThinMaterial.opacity(0.35))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 24)
                    */
                    
                    

                    // Account erstellen
                    Button {
                        Task { await createAccount() }
                    } label: {
                        HStack {
                            Spacer()
                            if isLoading {
                                ProgressView()
                            } else {
                                Text("Account erstellen")
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                        .frame(height: 50)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!canCreateAccount)
                    .padding(.horizontal, 24)
                    .padding(.top, 4)

                    Text("Durch erstellen eines Accounts stimmst du unseren AGB und der Datenschutzerklärung zu.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 6) {
                        Text("Du hast bereits einen Account?")
                            .font(.footnote)
                            .foregroundColor(.secondary)

                        // Falls deine Login-View anders heißt: hier ersetzen.
                        NavigationLink {
                            OnboardingView()
                        } label: {
                            Text("Einloggen")
                                .font(.footnote)
                                .fontWeight(.semibold)
                        }
                    }
                    .padding(.top, -6)
                    .padding(.bottom, 6)
                }
            }
        }
    }

    @MainActor
    private func createAccount() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            try await auth.signUpWithEmail(email: trimmedEmail, password: password)

            // Wenn SignUp eine Session erzeugt hat oder restoreSession erfolgreich war:
            if auth.isLoggedIn {
                hasCompletedOnboarding = true
            } else {
                // Falls du in Supabase "Confirm Email" aktiviert hast,
                // kann es sein, dass noch keine Session existiert.
                errorMessage = "Account erstellt. Bitte prüfe ggf. deine E-Mail zur Bestätigung und melde dich danach an."
            }
        } catch {
            errorMessage = "Registrierung fehlgeschlagen: \(error.localizedDescription)"
        }
    }
}


#Preview("Light Mode") {
    OnboardingRegisterView()
        .environmentObject(SupabaseAuthManager())
}

#Preview("Dark Mode") {
    OnboardingRegisterView()
        .environmentObject(SupabaseAuthManager())
        .preferredColorScheme(.dark)
}


