import SwiftUI
import AuthenticationServices

struct OnboardingRegisterView: View {
    @StateObject private var appleVM = AuthViewModel()
    @EnvironmentObject private var auth: SupabaseAuthManager

    @State private var email: String = ""
    @State private var password: String = ""

    @State private var isLoading: Bool = false
    @State private var errorMessage: String?

    @State private var showMailCodeView = false
    @State private var pendingEmail = ""
    @State private var pendingPassword = ""

    // MARK: - Password Requirements

    struct PasswordRequirement: Identifiable {
        let id = UUID()
        let title: String
        let isMet: Bool
    }

    private var trimmedEmail: String {
        email.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canCreateAccount: Bool {
        !trimmedEmail.isEmpty && isPasswordStrongEnough && !isLoading
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

    // MARK: - UI

    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(spacing: 0) {

                    // ───────── TOP ─────────
                    Text("Registrieren")
                        .font(.title)
                        .fontWeight(.semibold)
                        .padding(.top, 24)

                    Spacer(minLength: 0)

                    // ───────── CONTENT ─────────
                    VStack(spacing: 18) {

                        SignInWithAppleButton(
                            .signUp,
                            onRequest: appleVM.handleSignInWithAppleRequest,
                            onCompletion: { result in
                                Task {
                                    do {
                                        try await appleVM.handleSignInWithAppleCompletion(result, authManager: auth)
                                    } catch {
                                        errorMessage = "Apple Login fehlgeschlagen: \(error.localizedDescription)"
                                    }
                                }
                            }
                        )
                        .frame(height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .padding(.horizontal, 24)

                        HStack(spacing: 12) {
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(.secondary.opacity(0.35))

                            Text("Oder")
                                .font(.footnote)
                                .foregroundColor(.secondary)

                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(.secondary.opacity(0.35))
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

                        SecureField("Passwort", text: $password)
                            .textContentType(.newPassword)
                            .padding(14)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .padding(.horizontal, 24)

                        if showPasswordRequirements {
                            VStack(alignment: .leading, spacing: 6) {
                                ForEach(passwordRequirements) { req in
                                    HStack(spacing: 8) {
                                        Image(systemName: req.isMet ? "checkmark.circle.fill" : "xmark.circle.fill")
                                            .foregroundStyle(req.isMet ? .green : .red)

                                        Text(req.title)
                                            .font(.subheadline)
                                            .foregroundStyle(req.isMet ? .green : .red)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 24)
                        }

                        if let errorMessage {
                            Text(errorMessage)
                                .font(.subheadline)
                                .foregroundColor(.red)
                                .padding(.horizontal, 24)
                                .multilineTextAlignment(.center)
                        }
                    }

                    Spacer(minLength: 0)

                    // ───────── BOTTOM ─────────
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
                            .padding(.horizontal, 24)
                            .multilineTextAlignment(.center)

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
                        .padding(.bottom, 8)
                    }
                    .padding(.bottom, 40)
                }
                .frame(minHeight: geo.size.height, alignment: .top)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        // ✅ DAS ist der entscheidende Fix:
        .navigationDestination(isPresented: $showMailCodeView) {
            MailCodeView(email: pendingEmail, desiredPassword: pendingPassword)
                .environmentObject(auth)
        }
    }

    // MARK: - Actions

    @MainActor
    private func createAccount() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        let e = trimmedEmail
        do {
            // 1) OTP senden
            try await auth.sendEmailOTP(email: e)

            // 2) Werte merken + navigieren
            pendingEmail = e
            pendingPassword = password
            showMailCodeView = true
        } catch {
            errorMessage = "OTP konnte nicht gesendet werden: \(error.localizedDescription)"
        }
    }
}

// MARK: - Previews

#Preview("Light Mode") {
    OnboardingRegisterView()
        .environmentObject(SupabaseAuthManager())
}

#Preview("Dark Mode") {
    OnboardingRegisterView()
        .environmentObject(SupabaseAuthManager())
        .preferredColorScheme(.dark)
}
