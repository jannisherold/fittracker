import SwiftUI
import AuthenticationServices

struct OnboardingRegisterView: View {
    @StateObject private var appleVM = AuthViewModel()
    @EnvironmentObject private var auth: SupabaseAuthManager

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false

    @State private var email: String = ""
    @State private var password: String = ""
    //@State private var hasAcceptedLegal: Bool = false

    @State private var isLoading: Bool = false
    @State private var errorMessage: String?

    private var canCreateAccount: Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        isPasswordStrongEnough &&
        //hasAcceptedLegal &&
        !isLoading
    }

    
    private struct PasswordRequirement: Identifiable {
        let id = UUID()
        let title: String
        let isMet: Bool
    }

    private var trimmedEmail: String {
        email.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var showPasswordRequirements: Bool {
        !trimmedEmail.isEmpty
    }

    private var passwordRequirements: [PasswordRequirement] {
        let hasMinLength = password.count >= 8
        let hasLowercase = password.range(of: "[a-z]", options: .regularExpression) != nil
        let hasUppercase = password.range(of: "[A-Z]", options: .regularExpression) != nil
        let hasDigit     = password.range(of: "[0-9]", options: .regularExpression) != nil
        let hasSpecial   = password.range(of: #"[^A-Za-z0-9]"#, options: .regularExpression) != nil

        return [
            .init(title: "Mindestens 8 Zeichen", isMet: hasMinLength),
            .init(title: "Kleinbuchstabe", isMet: hasLowercase),
            .init(title: "Großbuchstabe", isMet: hasUppercase),
            .init(title: "Ziffer", isMet: hasDigit),
            .init(title: "Sonderzeichen", isMet: hasSpecial),
        ]
    }

    private var isPasswordStrongEnough: Bool {
        passwordRequirements.allSatisfy { $0.isMet }
    }


    var body: some View {
        
            GeometryReader { geo in
                ScrollView {
                    VStack(spacing: 0) {

                        // ───────── TOP: fix ─────────
                        Text("Registrieren")
                            .font(.title)
                            .fontWeight(.semibold)
                            .padding(.top, 24)

                        // der dynamische Abstand
                        Spacer(minLength: 0)

                        VStack(spacing: 18){
                            SignInWithAppleButton(
                                .signUp,
                                onRequest: appleVM.handleSignInWithAppleRequest,
                                onCompletion: { result in
                                    Task {
                                        do {
                                            try await appleVM.handleSignInWithAppleCompletion(result, authManager: auth)
                                            hasCompletedOnboarding = true
                                        } catch {
                                            errorMessage = "Apple Login fehlgeschlagen: \(error.localizedDescription)"
                                        }
                                    }
                                }
                            )
                            //.signInWithAppleButtonStyle(.black)
                            .frame(height: 50)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .padding(.horizontal, 24)

                            HStack(spacing: 12) {
                                Rectangle().frame(height: 1).foregroundColor(.secondary.opacity(0.35))
                                Text("Oder")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                                Rectangle().frame(height: 1).foregroundColor(.secondary.opacity(0.35))
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 6)

                            TextField("E-Mail Adresse", text: $email)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .keyboardType(.emailAddress)
                                .textContentType(.emailAddress)
                                .padding(14)
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .padding(.horizontal, 24)

                            VStack(alignment: .leading, spacing: 8) {
                                SecureField("Passwort", text: $password)
                                    .textContentType(.newPassword)
                                    .padding(14)
                                    .background(.ultraThinMaterial)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                            }
                            .padding(.horizontal, 24)
                            
                            if showPasswordRequirements {
                                VStack(alignment: .leading, spacing: 6) {
                                    ForEach(passwordRequirements) { req in
                                        HStack(spacing: 8) {
                                            Image(systemName: req.isMet ? "checkmark.circle.fill" : "xmark.circle.fill")
                                                .foregroundStyle(req.isMet ? .green : .red)

                                            Text(req.title)
                                                .font(.footnote)
                                                .foregroundColor(req.isMet ? .green : .red)
                                        }
                                    }
                                }
                                .padding(.top, 6)
                            }


                            if let errorMessage {
                                Text(errorMessage)
                                    .font(.footnote)
                                    .foregroundColor(.red)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 24)
                            }
                        }
                        
                        
                        Spacer(minLength: 0)
                        
                        
                        
                        // ───────── BOTTOM: "klebt" unten ─────────
                        VStack(spacing: 18) {

                            

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

                                NavigationLink {
                                    LoginView()
                                } label: {
                                    Text("Einloggen")
                                        .font(.footnote)
                                        .fontWeight(.semibold)
                                }
                            }
                            .padding(.top, -6)
                            .padding(.bottom, 6)
                        }
                        .padding(.bottom, 40)
                    }
                    // 👇 DER entscheidende Punkt: Content bekommt Bildschirmhöhe
                    .frame(minHeight: geo.size.height, alignment: .top)
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


