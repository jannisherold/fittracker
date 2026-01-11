import SwiftUI

/// Letzter Registrierungsschritt (Variante 1):
/// - Nutzer bestätigt/ändert Name + Kontakt-Mail
/// - optional Marketing Opt-in
/// - Links zu AGB/Datenschutz
/// - Erst nach erfolgreichem Supabase-Upsert wird `hasFinalizedRegistration = true`
struct FinalizeRegistrationView: View {
    @EnvironmentObject private var auth: SupabaseAuthManager

    @AppStorage("hasFinalizedRegistration") private var hasFinalizedRegistration: Bool = false
    @AppStorage("hasCreatedAccount") private var hasCreatedAccount: Bool = false

    @AppStorage("userGoal") private var storedGoal: String = ""
    @AppStorage("onboardingGoal") private var onboardingGoal: String = ""

    @AppStorage("pendingFirstName") private var pendingFirstName: String = ""
    @AppStorage("pendingLastName") private var pendingLastName: String = ""
    @AppStorage("pendingContactEmail") private var pendingContactEmail: String = ""

    @AppStorage("pendingFirstName") private var firstName: String = ""
    @AppStorage("pendingLastName") private var lastName: String = ""
    @AppStorage("pendingContactEmail") private var contactEmail: String = ""

    @State private var marketingOptIn: Bool = false

    @State private var isWorking: Bool = false
    @State private var errorMessage: String?

    // TODO: Ersetze diese URLs durch deine echten Links
    private let termsURL = URL(string: "https://example.com/agb")
    private let privacyURL = URL(string: "https://example.com/datenschutz")

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section {
                    TextField("Vorname", text: $firstName)
                        .textContentType(.givenName)
                        .autocorrectionDisabled()
                    TextField("Nachname", text: $lastName)
                        .textContentType(.familyName)
                        .autocorrectionDisabled()
                    TextField("Kontakt E-Mail", text: $contactEmail)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } header: {
                    Text("Deine Daten")
                }

                Section {
                    Toggle("Ich möchte E-Mails mit Updates erhalten", isOn: $marketingOptIn)
                }

                Section {
                    if let termsURL {
                        Link("AGB anzeigen", destination: termsURL)
                    } else {
                        Text("AGB anzeigen")
                            .foregroundStyle(.secondary)
                    }

                    if let privacyURL {
                        Link("Datenschutzerklärung anzeigen", destination: privacyURL)
                    } else {
                        Text("Datenschutzerklärung anzeigen")
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    Button {
                        Task { await finalize() }
                    } label: {
                        HStack {
                            Spacer()
                            Text(isWorking ? "Wird registriert…" : "Account erstellen")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(isWorking)

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    }

                    Text("Mit der Registrierung stimmst du unseren AGB und der Datenschutzerklärung zu.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .navigationTitle("Account erstellen")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    Task {
                        // Zurück zur OnboardingRegisterView => Session verlassen
                        await auth.signOut()

                        // Sicherheits-halber: Gate zu lassen
                        hasFinalizedRegistration = false
                        hasCreatedAccount = false
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                }
                .disabled(isWorking)
            }
        }


    }

    @MainActor
    private func finalize() async {
        errorMessage = nil

        let fn = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let ln = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        let mail = contactEmail.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !fn.isEmpty else {
            errorMessage = "Bitte gib deinen Vornamen ein."
            return
        }
        guard !mail.isEmpty, mail.contains("@") else {
            errorMessage = "Bitte gib eine gültige Kontakt E-Mail ein."
            return
        }

        let goal = storedGoal.isEmpty ? (onboardingGoal.isEmpty ? "Überspringen" : onboardingGoal) : storedGoal

        isWorking = true
        defer { isWorking = false }

        do {
            try await auth.finalizeRegistration(
                contactEmail: mail,
                firstName: fn,
                lastName: ln,
                goal: goal,
                marketingOptIn: marketingOptIn
            )

            // Registrierung gilt als abgeschlossen
            hasFinalizedRegistration = true
            hasCreatedAccount = true
        } catch {
            errorMessage = "Registrierung fehlgeschlagen. Bitte prüfe deine Internetverbindung und versuche es erneut. (\(error.localizedDescription))"
        }
    }
}

#Preview {
    NavigationStack {
        FinalizeRegistrationView()
            .environmentObject(SupabaseAuthManager())
    }
}
