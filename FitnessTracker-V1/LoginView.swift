import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @StateObject private var appleVM = AuthViewModel()
    @EnvironmentObject private var auth: SupabaseAuthManager

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @AppStorage("hasCreatedAccount") private var hasCreatedAccount: Bool = false

    @AppStorage("userEmail") private var storedEmail: String = ""
    @AppStorage("userName") private var storedName: String = ""
    @AppStorage("userGoal") private var storedGoal: String = ""
    @AppStorage("onboardingGoal") private var onboardingGoal: String = ""

    @State private var errorMessage: String?

    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(spacing: 0) {

                    Text("Anmelden")
                        .font(.title)
                        .fontWeight(.semibold)
                        .padding(.top, 24)

                    Spacer(minLength: 0)

                    VStack(spacing: 16) {
                        SignInWithAppleButton(
                            .signIn,
                            onRequest: appleVM.handleSignInWithAppleRequest,
                            onCompletion: { result in
                                Task {
                                    do {
                                        let profile = try await appleVM
                                            .handleSignInWithAppleCompletionAndReturnProfile(result, authManager: auth)

                                        // ✅ Flags
                                        hasCompletedOnboarding = true
                                        hasCreatedAccount = true

                                        // ✅ Lokal speichern (Apple liefert Email/Name evtl. nur beim ersten Mal)
                                        if !profile.email.isEmpty { storedEmail = profile.email }
                                        if !profile.name.isEmpty { storedName = profile.name }
                                        if storedGoal.isEmpty {
                                            storedGoal = onboardingGoal.isEmpty ? "Überspringen" : onboardingGoal
                                        }

                                        // ✅ Optional: in DB speichern (falls Tabelle existiert)
                                        await auth.upsertProfile(
                                            email: storedEmail.isEmpty ? auth.userEmail : storedEmail,
                                            name: storedName.isEmpty ? "User" : storedName,
                                            goal: storedGoal.isEmpty ? "Überspringen" : storedGoal
                                        )

                                    } catch {
                                        errorMessage = "Apple Login fehlgeschlagen: \(error.localizedDescription)"
                                    }
                                }
                            }
                        )
                        .frame(height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .padding(.horizontal, 24)

                        Text("Email + Passwort ist im MVP deaktiviert.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)

                        if let errorMessage {
                            Text(errorMessage)
                                .font(.footnote)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                                .padding(.top, 6)
                        }
                    }

                    Spacer(minLength: 0)

                    VStack(spacing: 10) {
                        Text("Durch die Anmeldung stimmst du unseren AGB und der Datenschutzerklärung zu.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                    .padding(.bottom, 40)
                }
                .frame(minHeight: geo.size.height, alignment: .top)
            }
        }
        .navigationBarBackButtonHidden(true)
        .interactiveDismissDisabled(true)
    }
}

#Preview("Login") {
    NavigationStack {
        LoginView()
            .environmentObject(SupabaseAuthManager())
    }
}
