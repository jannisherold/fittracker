import SwiftUI
import AuthenticationServices

struct OnboardingRegisterView: View {
    @StateObject private var appleVM = AuthViewModel()
    @EnvironmentObject private var auth: SupabaseAuthManager

    @AppStorage("userEmail") private var storedEmail: String = ""
    @AppStorage("userFirstName") private var storedFirstName: String = ""
    @AppStorage("userLastName") private var storedLastName: String = ""
    @AppStorage("userGoal") private var storedGoal: String = ""
    @AppStorage("onboardingGoal") private var onboardingGoal: String = ""
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @AppStorage("hasCreatedAccount") private var hasCreatedAccount: Bool = false

    @State private var errorMessage: String?
    @State private var isWorking: Bool = false

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            VStack(spacing: 10) {
                Image(systemName: "icloud.and.arrow.up")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(.blue)

                Text("Account erstellen")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Damit deine Daten sicher gespeichert werden.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 24)

            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .font(.footnote)
                    .padding(.horizontal, 24)
                    .multilineTextAlignment(.center)
            }

            SignInWithAppleButton(
                .continue,
                onRequest: appleVM.handleSignInWithAppleRequest,
                onCompletion: { result in
                    Task { await handleRegister(result) }
                }
            )
            .signInWithAppleButtonStyle(.black)
            .frame(height: 52)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .padding(.horizontal, 24)

            if isWorking {
                ProgressView().padding(.top, 8)
            }

            VStack(spacing: 12) {
                
                
                HStack(spacing: 6) {
                    Text("Du hast bereits einen Account?")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    
                    Button {
                        // Nutzer hat schon einen Account -> AppRootView soll Login zeigen
                        hasCreatedAccount = true
                        hasCompletedOnboarding = true
                    } label: {
                        Text("Einloggen")
                            .font(.footnote)
                            .fontWeight(.semibold)
                    }
                }
                
                Text("Durch die Registrierung stimmst du unseren AGB und der Datenschutzerklärung zu.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 24)
                    .multilineTextAlignment(.center)
                //.padding(.bottom, 16)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
    }

    @MainActor
    private func handleRegister(_ result: Result<ASAuthorization, Error>) async {
        errorMessage = nil
        isWorking = true
        defer { isWorking = false }

        do {
            let profile = try await appleVM.handleSignInWithAppleCompletionAndReturnProfile(result, authManager: auth)

            let goal = storedGoal.isEmpty ? (onboardingGoal.isEmpty ? "Überspringen" : onboardingGoal) : storedGoal
            let email = profile.email.isEmpty ? auth.userEmail : profile.email

            // ✅ Vor-/Nachname kommen idealerweise aus AuthViewModel (first/last),
            // falls du dort noch "name" hast, splitte es bitte dort – diese View erwartet first/last in Auth-Flow.
            // Fürs Minimum setzen wir hier erstmal lokale Werte, die später durch sync überschrieben werden.
            // (Wenn du AuthViewModel bereits umgebaut hast, passt es direkt.)
            let fn = storedFirstName
            let ln = storedLastName

            try await auth.upsertProfile(email: email, firstName: fn, lastName: ln, goal: goal)
            await auth.syncProfileFromBackendToLocal()

            hasCompletedOnboarding = true
            hasCreatedAccount = true
        } catch {
            errorMessage = "Apple Registrierung fehlgeschlagen: \(error.localizedDescription)"
        }
    }
}
