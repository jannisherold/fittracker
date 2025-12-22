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
                VStack(spacing: 18) {

                    Spacer().frame(height: 16)

                    Text("Einloggen")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundColor(.red)
                            .padding(.horizontal, 24)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // Apple Sign In
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
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 52)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .padding(.horizontal, 24)
                    .padding(.top, 10)

                    Spacer(minLength: 24)

                    VStack(spacing: 12) {
                        HStack(spacing: 6) {
                            Text("Du hast noch keinen Account?")
                                .font(.footnote)
                                .foregroundColor(.secondary)

                            Button {
                                // ✅ B) Registrierung soll wieder bei Onboarding Screen 1 starten
                                hasCompletedOnboarding = false
                                hasCreatedAccount = false
                            } label: {
                                Text("Registrieren")
                                    .font(.footnote)
                                    .fontWeight(.semibold)
                            }
                        }

                        Text("Durch die Registrierung stimmst du unseren AGB und der Datenschutzerklärung zu.")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 24)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(minHeight: geo.size.height, alignment: .top)
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}
