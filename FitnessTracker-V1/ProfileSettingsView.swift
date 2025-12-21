import SwiftUI

struct ProfileSettingsView: View {
    @EnvironmentObject var store: Store

    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false
    @AppStorage("appleUserID") private var appleUserID: String = ""
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @AppStorage("appleFirstName") private var appleFirstName: String = ""
    @AppStorage("appleLastName")  private var appleLastName: String = ""
    @AppStorage("appleEmail")     private var appleEmail: String = ""

    // MARK: - Alert Handling

    private enum ActiveAlert: Identifiable {
        case resetBodyweight
        case deleteAllData

        var id: Int { hashValue }
    }

    @State private var activeAlert: ActiveAlert?

    var body: some View {
        List {
            // 🔹 Account-Daten
            Section("Account") {
                /*
                HStack {
                    Text("Name")
                    Spacer()
                    Text("\(appleFirstName) \(appleLastName)")
                        .foregroundStyle(.secondary)
                }

                 */
                
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

                
            } 

            // 🔹 Daten-Section
            Section{
                Button(role: .destructive) {
                    activeAlert = .resetBodyweight
                } label: {
                    Label("Körpergewicht zurücksetzen", systemImage: "scalemass")
                }

                Button(role: .destructive) {
                    activeAlert = .deleteAllData
                } label: {
                    Label("Alle Daten löschen", systemImage: "trash.slash")
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
                Text("„Körpergewicht zurücksetzen“ entfernt nur deine Körpergewichts-Historie. „Alle Daten löschen“ setzt die App vollständig zurück, inklusive aller Workouts, Sessions und Statistiken.")
            }
            
            Section{
                Text("Abmelden")
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
                    message: Text("Alle Workouts, Sessions und Körpergewichtsdaten werden dauerhaft gelöscht. Dieser Vorgang kann nicht rückgängig gemacht werden."),
                    primaryButton: .destructive(Text("Alle Daten löschen")) {
                        store.deleteAllData()
                    },
                    secondaryButton: .cancel(Text("Abbrechen"))
                )
            }
        }
    }
}
