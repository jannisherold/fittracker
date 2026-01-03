import SwiftUI

struct SettingsProfileView: View {
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

    // ✅ Popover/Menu State nicht mehr nötig – Apple-native Menu/Picker handled das
    @State private var lastSavedGoal: String = ""

    // ✅ Ziele (wie zuvor im Popover)
    private let goals: [String] = [
        "Muskeln aufbauen",
        "Gewicht abnehmen",
        "Kraft steigern",
        "Routine aufbauen",
        "Fit bleiben",
        "sonstiges"

    ]

    var body: some View {
        List {
            // --- Apple-Account-ähnlicher Header ---
            Section {
                VStack(spacing: 0) {
                    Image(systemName: "person.crop.circle")
                        .font(.system(size: 84, weight: .regular))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.blue)

                    VStack {
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
                    SettingsPersonalDataView()
                } label: {
                    HStack(spacing: 0) {
                        Image(systemName: "person.text.rectangle")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.secondary)
                    }

                    Text("Persönliche Daten")
                    Spacer()
                }

                NavigationLink {
                    WorkoutView()
                } label: {
                    HStack(spacing: 0) {
                        Image(systemName: "text.document")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.secondary)
                    }

                    Text("Abonnement verwalten")
                    Spacer()
                }
            }

            // --- Inhalt wie bisher (nur Ziel: Apple-native Menu/Picker am Chevron) ---
            Section {
                HStack {
                    HStack(spacing: 0) {
                        Image(systemName: "text.document")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                    
                    
                    Text("Ziel")
                    Spacer()

                    
                    
                 
                    // ✅ Nur der Chevron öffnet die Auswahl (wie Reminders)
                    Menu {
                        Picker("Ziel", selection: $storedGoal) {
                            ForEach(goals, id: \.self) { goal in
                                Text(goal).tag(goal)
                            }
                        }
                    } label: {
                        HStack{
                            Text(storedGoal.isEmpty ? "—" : storedGoal)
                                //.foregroundStyle(.secondary)
                                //.lineLimit(1)
                                //.truncationMode(.tail)
                            
                            Image(systemName: "chevron.up.chevron.down")
                                //.frame(width: 44, height: 44, alignment: .trailing)
                        }
                        
                    }
                    .disabled(isWorking)
                }
            }


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
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            lastSavedGoal = storedGoal
        }
        .onChange(of: storedGoal) { _, newValue in
            // ✅ Verhindert unnötige Loops, z.B. durch syncProfileFromBackendToLocal()
            guard newValue != lastSavedGoal else { return }
            lastSavedGoal = newValue
            Task { await updateGoal(newValue) }
        }
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
    private func updateGoal(_ newGoal: String) async {
        errorMessage = nil
        isWorking = true
        defer { isWorking = false }

        // Optional: konsistent halten (wird auch als Fallback genutzt)
        onboardingGoal = newGoal

        do {
            // ✅ Name/Email für Upsert verwenden (wie dein restlicher Flow)
            let email = displayEmail == "—" ? auth.userEmail : displayEmail
            let name = displayName

            try await auth.upsertProfile(email: email, name: name, goal: newGoal)
            await auth.syncProfileFromBackendToLocal()
        } catch {
            errorMessage = "Ziel konnte nicht gespeichert werden: \(error.localizedDescription)"
        }
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
