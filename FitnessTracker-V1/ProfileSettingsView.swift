import SwiftUI

struct ProfileSettingsView: View {
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false
    @AppStorage("appleUserID") private var appleUserID: String = ""
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false

    // 🔽 neu:
    @AppStorage("appleFirstName") private var appleFirstName: String = ""
    @AppStorage("appleLastName")  private var appleLastName: String = ""
    @AppStorage("appleEmail")     private var appleEmail: String = ""

    var body: some View {
        List {
            // 🔹 Account-Daten
            Section("Account") {
                HStack {
                    Text("Name")
                    Spacer()
                    Text("\(appleFirstName) \(appleLastName)")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("E-Mail")
                    Spacer()
                    Text(appleEmail)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }

            Section {
                // (Optional) Abo-Platzhalter
                Label("Abonnement", systemImage: "receipt")

                Button {
                    isLoggedIn = false
                } label: {
                    Label("Abmelden", systemImage: "rectangle.portrait.and.arrow.right")
                }

                Button(role: .destructive) {
                    // Lokale Account-Daten entfernen
                    appleUserID = ""
                    hasCompletedOnboarding = false
                    isLoggedIn = false

                    // 🔽 optional: gespeicherte Profildaten ebenfalls löschen
                    appleFirstName = ""
                    appleLastName = ""
                    appleEmail = ""
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
