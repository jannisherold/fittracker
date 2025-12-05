import SwiftUI

struct ProfileSettingsView: View {
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false
    @AppStorage("appleUserID") private var appleUserID: String = ""
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false

    var body: some View {
        List {
            Section {
                // (Optional) Abo-Platzhalter
                Label("Abonnement", systemImage: "receipt")

                // MARK: - Abmelden (nur Logout, Account bleibt bestehen)
                Button {
                    isLoggedIn = false
                } label: {
                    Label("Abmelden", systemImage: "rectangle.portrait.and.arrow.right")
                }

                // MARK: - Profil löschen (optional, kompletter Reset)
                Button(role: .destructive) {
                    // Lokale Account-Daten entfernen
                    appleUserID = ""
                    hasCompletedOnboarding = false
                    isLoggedIn = false
                } label: {
                    Label("Profil löschen", systemImage: "trash")
                }
            } footer: {
                Text("Abmelden beendet deine aktuelle Sitzung. „Profil löschen“ setzt den lokalen Account zurück (App startet wieder im Onboarding).")
            }
        }
        .navigationTitle("Profil")
    }
}
