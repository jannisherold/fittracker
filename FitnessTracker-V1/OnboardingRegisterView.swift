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
    @AppStorage("hasFinalizedRegistration") private var hasFinalizedRegistration: Bool = false

    // Pending (wird nach SIWA vorbefüllt und in FinalizeRegistrationView bestätigt)
    @AppStorage("pendingFirstName") private var pendingFirstName: String = ""
    @AppStorage("pendingLastName") private var pendingLastName: String = ""
    @AppStorage("pendingContactEmail") private var pendingContactEmail: String = ""

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
            let contactEmail = profile.email.isEmpty ? auth.userEmail : profile.email

            // ✅ Ab hier NICHT sofort in `profiles` schreiben.
            // Wir füllen nur die Pending-Infos vor, die der Nutzer im nächsten Screen bestätigt.
            // (Registrierung ist erst nach Finalisierung abgeschlossen.)
            let fn = profile.firstName.isEmpty ? storedFirstName : profile.firstName
            let ln = profile.lastName.isEmpty ? storedLastName : profile.lastName

            pendingFirstName = fn
            pendingLastName = ln
            pendingContactEmail = contactEmail
            storedGoal = goal

            // Wichtig: AppRootView zeigt nun FinalizeRegistrationView, solange hasFinalizedRegistration == false.
            hasFinalizedRegistration = false
            hasCompletedOnboarding = true
        } catch {
            errorMessage = "Apple Registrierung fehlgeschlagen: \(error.localizedDescription)"
        }
    }
}
