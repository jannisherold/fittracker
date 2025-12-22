import SwiftUI

struct ProfileSettingsView: View {
    @EnvironmentObject private var store: Store
    @EnvironmentObject private var auth: SupabaseAuthManager

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @AppStorage("hasCreatedAccount") private var hasCreatedAccount: Bool = false

    @AppStorage("userEmail") private var storedEmail: String = ""
    @AppStorage("userName") private var storedName: String = ""
    @AppStorage("userGoal") private var storedGoal: String = ""
    @AppStorage("onboardingGoal") private var onboardingGoal: String = ""

    private enum ActiveAlert: Identifiable {
        case resetBodyweight
        case deleteAllData
        case deleteProfile
        case signOut
        var id: Int { hashValue }
    }

    @State private var activeAlert: ActiveAlert?
    @State private var isWorking: Bool = false
    @State private var errorMessage: String?

    var body: some View {
        List {
            Section("Account") {
                HStack {
                    Text("E-Mail")
                    Spacer()
                    Text(displayEmail)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                HStack {
                    Text("Name")
                    Spacer()
                    Text(storedName.isEmpty ? "—" : storedName)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                HStack {
                    Text("Ziel")
                    Spacer()
                    Text(storedGoal.isEmpty ? "—" : storedGoal)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Section {
                Label("Abonnement", systemImage: "receipt")
                    .foregroundStyle(.secondary)
            }

            Section {
                Button(role: .destructive) { activeAlert = .resetBodyweight } label: {
                    Label("Körpergewicht zurücksetzen", systemImage: "scalemass")
                }
                .disabled(isWorking)

                Button(role: .destructive) { activeAlert = .deleteProfile } label: {
                    Label("Profil löschen", systemImage: "trash")
                }
                .disabled(isWorking)

            } footer: {
                VStack(alignment: .leading, spacing: 8) {
                    Text("„Körpergewicht zurücksetzen“ entfernt nur deine Körpergewichts-Historie. „Alle Daten löschen“ setzt die App lokal zurück. „Profil löschen“ entfernt zusätzlich deinen Supabase Account.")
                    if let errorMessage {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.footnote)
                    }
                }
            }

            Section {
                Button(role: .destructive) { activeAlert = .signOut } label: {
                    Label("Abmelden", systemImage: "rectangle.portrait.and.arrow.right")
                }
                .disabled(isWorking)
            }
        }
        .navigationTitle("Profil")
        .alert(item: $activeAlert) { alert in
            switch alert {
            case .resetBodyweight:
                return Alert(
                    title: Text("Körpergewicht zurücksetzen?"),
                    message: Text("Alle gespeicherten Körpergewichtsdaten werden dauerhaft gelöscht."),
                    primaryButton: .destructive(Text("Körpergewicht löschen")) {
                        store.resetBodyweightEntries()
                    },
                    secondaryButton: .cancel(Text("Abbrechen"))
                )

            case .deleteAllData:
                return Alert(
                    title: Text("Alle Daten löschen?"),
                    message: Text("Alle Workouts, Sessions und Körpergewichtsdaten werden lokal dauerhaft gelöscht."),
                    primaryButton: .destructive(Text("Alle Daten löschen")) {
                        store.deleteAllData()
                    },
                    secondaryButton: .cancel(Text("Abbrechen"))
                )

            case .deleteProfile:
                return Alert(
                    title: Text("Profil wirklich löschen?"),
                    message: Text("Dein Account (Supabase) und alle lokalen App-Daten werden dauerhaft gelöscht. Das kann nicht rückgängig gemacht werden."),
                    primaryButton: .destructive(Text("Profil löschen")) {
                        Task { await deleteProfile() }
                    },
                    secondaryButton: .cancel(Text("Abbrechen"))
                )

            case .signOut:
                return Alert(
                    title: Text("Abmelden?"),
                    message: Text("Du wirst abgemeldet und gelangst zurück zum Login."),
                    primaryButton: .destructive(Text("Abmelden")) {
                        Task { await signOut() }
                    },
                    secondaryButton: .cancel(Text("Abbrechen"))
                )
            }
        }
    }

    private var displayEmail: String {
        let supa = auth.userEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        if !supa.isEmpty { return supa }
        if !storedEmail.isEmpty { return storedEmail }
        return "—"
    }

    @MainActor
    private func signOut() async {
        errorMessage = nil
        isWorking = true
        defer { isWorking = false }

        await auth.signOut()
        // Flags bleiben: Onboarding abgeschlossen + Account existiert -> Root zeigt LoginView
    }

    @MainActor
    private func deleteProfile() async {
        errorMessage = nil
        isWorking = true
        defer { isWorking = false }

        do {
            // 1) Supabase Auth User löschen
            try await auth.deleteCurrentUser()

            // 2) Lokal alles löschen
            store.deleteAllData()

            // 3) App wieder "neu" machen -> OnboardingView
            resetAppStateToFreshInstall()

        } catch {
            // Fallback: wenigstens lokal resetten + ausloggen,
            // damit der Nutzer nicht hängen bleibt.
            store.deleteAllData()
            await auth.signOut()
            resetAppStateToFreshInstall()

            errorMessage = "Account konnte serverseitig nicht gelöscht werden. Lokal wurde alles zurückgesetzt. Fehler: \(error.localizedDescription)"
        }
    }

    private func resetAppStateToFreshInstall() {
        hasCompletedOnboarding = false
        hasCreatedAccount = false

        storedEmail = ""
        storedName = ""
        storedGoal = ""
        onboardingGoal = ""
    }
}
