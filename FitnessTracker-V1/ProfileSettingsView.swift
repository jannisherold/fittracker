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
            // --- Apple-Account-ähnlicher Header ---
            Section {
                VStack(spacing: 0) {
                    Image(systemName: "person.crop.circle")
                        .font(.system(size: 84, weight: .regular))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.blue)
                        //.foregroundStyle(.secondary)
                        //.padding(.top, 6)
                    
                    VStack{
                        Text(displayName)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.center)

                        Text(displayEmail)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 6)

                    
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }
            .textCase(nil)
            .listRowBackground(Color.clear)

            Section() {
                NavigationLink {
                    PersonalDataView()
                } label: {
                    
                    HStack(spacing: 0) {
                       
                            Image(systemName: "person.text.rectangle")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.secondary)
                                //.frame(width: 28, alignment: .leading)
                                //.foregroundStyle(.blue)
                        }

                        Text("Persönliche Daten")
                            //.font(.system(size: 22, weight: .semibold))   // H2-ähnlich
                            //.foregroundColor(.primary)                     // Schwarz

                        Spacer()
                    
                   
                }
                
                NavigationLink {
                    WorkoutView()
                } label: {
                    HStack(spacing: 0) {
                       
                            Image(systemName: "scalemass")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.secondary)
                                //.frame(width: 28, alignment: .leading)
                                //.foregroundStyle(.blue)
                        }

                        Text("Abonnement verwalten")
                            //.font(.system(size: 22, weight: .semibold))   // H2-ähnlich
                            //.foregroundColor(.primary)                     // Schwarz

                        Spacer()
                }
                
            }
            
            // --- Inhalt wie bisher (nur Layout angepasst) ---
            Section{
    
                
                
                HStack {
                    Text("Ziel")
                    Spacer()
                    Text(storedGoal.isEmpty ? "—" : storedGoal)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                
                HStack {
                    Text("Abonnement verwalten")
                    Spacer()
                    
                }
                
                
            }

            /*
            Section {
                Button(role: .destructive) { activeAlert = .resetBodyweight } label: {
                    Label("Körpergewicht zurücksetzen", systemImage: "scalemass")
                }
                .disabled(isWorking)

                Button(role: .destructive) {
                    activeAlert = .deleteProfile
                } label: {
                    Label("Progress Account löschen", systemImage: "trash")
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
            */

            // --- Abmelden: ganz unten, zentriert, nur Text ---
            Section {
                Button(role: .destructive) { activeAlert = .signOut } label: {
                    Text("Abmelden")
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .disabled(isWorking)
            }
        }
        .toolbar(.hidden, for: .tabBar)
        .listStyle(.insetGrouped)
        //.navigationTitle("Profil")
        .navigationBarTitleDisplayMode(.inline)
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

    private var displayName: String {
        let name = storedName.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? "User" : name
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
            try await auth.deleteAccountCompletely()

            // 2) Lokal alles löschen
            store.deleteAllData()

            // 3) App wieder "neu" machen -> OnboardingView
            resetAppStateToFreshInstall()

        } catch {
      
            // ❌ NICHT lokal alles resetten, wenn der Server-Delete fehlschlägt
            errorMessage = "Account konnte NICHT serverseitig gelöscht werden.\nFehler: \(error.localizedDescription)\n\nBitte erneut versuchen."

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
