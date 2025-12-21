import SwiftUI

struct ProfileSettingsView: View {
    @EnvironmentObject private var store: Store
    @EnvironmentObject private var auth: SupabaseAuthManager

    // Onboarding-Flag: nur relevant, um nach Delete sicher NICHT zurück ins Onboarding zu fallen
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false

    // (Legacy) Apple-Felder: optional beibehalten, damit du sie bei Delete/SignOut sauber leeren kannst
    @AppStorage("appleUserID") private var appleUserID: String = ""
    @AppStorage("appleFirstName") private var appleFirstName: String = ""
    @AppStorage("appleLastName")  private var appleLastName: String = ""
    @AppStorage("appleEmail")     private var appleEmail: String = ""

    // MARK: - UI State

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
            // 🔹 Account
            Section("Account") {
                HStack {
                    Text("E-Mail")
                    Spacer()
                    Text(displayEmail)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }

            // 🔹 Abo Platzhalter
            Section {
                Label("Abonnement", systemImage: "receipt")
                    .foregroundStyle(.secondary)
            }

            // 🔹 Daten
            Section {
                Button(role: .destructive) {
                    activeAlert = .resetBodyweight
                } label: {
                    Label("Körpergewicht zurücksetzen", systemImage: "scalemass")
                }
                .disabled(isWorking)

                Button(role: .destructive) {
                    activeAlert = .deleteAllData
                } label: {
                    Label("Alle Daten löschen", systemImage: "trash.slash")
                }
                .disabled(isWorking)

                Button(role: .destructive) {
                    activeAlert = .deleteProfile
                } label: {
                    Label("Profil löschen", systemImage: "trash")
                }
                .disabled(isWorking)

            } footer: {
                VStack(alignment: .leading, spacing: 8) {
                    Text("„Körpergewicht zurücksetzen“ entfernt nur deine Körpergewichts-Historie. „Alle Daten löschen“ setzt die App lokal vollständig zurück, inklusive aller Workouts, Sessions und Statistiken.")
                    if let errorMessage {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.footnote)
                    }
                }
            }

            // 🔹 Abmelden
            Section {
                Button(role: .destructive) {
                    activeAlert = .signOut
                } label: {
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
                    message: Text("Alle gespeicherten Körpergewichtsdaten werden dauerhaft gelöscht. Dieser Vorgang kann nicht rückgängig gemacht werden."),
                    primaryButton: .destructive(Text("Körpergewicht löschen")) {
                        store.resetBodyweightEntries()
                    },
                    secondaryButton: .cancel(Text("Abbrechen"))
                )

            case .deleteAllData:
                return Alert(
                    title: Text("Alle Daten löschen?"),
                    message: Text("Alle Workouts, Sessions und Körpergewichtsdaten werden lokal dauerhaft gelöscht. Dieser Vorgang kann nicht rückgängig gemacht werden."),
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
                    message: Text("Du wirst abgemeldet und gelangst zurück zum Login/Registrieren."),
                    primaryButton: .destructive(Text("Abmelden")) {
                        Task { await signOut() }
                    },
                    secondaryButton: .cancel(Text("Abbrechen"))
                )
            }
        }
    }

    private var displayEmail: String {
        // Bevorzugt: Supabase Session Email
        let supa = auth.userEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        if !supa.isEmpty { return supa }

        // Fallback: alte Apple AppStorage Email
        let apple = appleEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        if !apple.isEmpty { return apple }

        return "—"
    }

    @MainActor
    private func signOut() async {
        errorMessage = nil
        isWorking = true
        defer { isWorking = false }

        // optional: lokale Daten behalten oder löschen – dein Call
        // store.deleteAllData()

        await auth.signOut()
        clearLegacyAppleCache()
        // Onboarding nicht anfassen -> Root zeigt Register/Login (weil auth.isLoggedIn == false)
    }

    @MainActor
    private func deleteProfile() async {
        errorMessage = nil
        isWorking = true
        defer { isWorking = false }

        do {
            // 1) Server: Supabase Auth-User löschen (Edge Function, siehe Anleitung unten)
            // Wenn die Function noch nicht existiert, kommentiere die Zeile aus – dann wird nur lokal gelöscht + abgemeldet.
            try await SupabaseManager.shared.client.functions.invoke("delete-account")

            // 2) Lokal: alle Daten löschen
            store.deleteAllData()

            // 3) Abmelden
            await auth.signOut()

            // 4) Damit du nach Delete sicher NICHT zurück ins Onboarding fällst:
            hasCompletedOnboarding = true

            // 5) Legacy-Apple Cache leeren
            clearLegacyAppleCache()

        } catch {
            // Fallback: zumindest lokal löschen + abmelden, damit UI wieder “clean” ist
            store.deleteAllData()
            await auth.signOut()
            hasCompletedOnboarding = true
            clearLegacyAppleCache()

            errorMessage = "Profil konnte serverseitig nicht gelöscht werden (Edge Function fehlt/fehlerhaft). Lokal wurde alles zurückgesetzt. Fehler: \(error.localizedDescription)"
        }
    }

    private func clearLegacyAppleCache() {
        appleUserID = ""
        appleFirstName = ""
        appleLastName = ""
        appleEmail = ""
    }
}
