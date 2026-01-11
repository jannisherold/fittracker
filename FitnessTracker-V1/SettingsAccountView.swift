import SwiftUI

struct SettingsAccountView: View {
    @EnvironmentObject private var store: Store
    @EnvironmentObject private var auth: SupabaseAuthManager
    @EnvironmentObject private var sync: SyncManager

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @AppStorage("hasCreatedAccount") private var hasCreatedAccount: Bool = false

    @AppStorage("userEmail") private var storedEmail: String = ""
    @AppStorage("userFirstName") private var storedFirstName: String = ""
    @AppStorage("userLastName") private var storedLastName: String = ""

    @AppStorage("userGoal") private var storedGoal: String = ""
    @AppStorage("onboardingGoal") private var onboardingGoal: String = ""
    
    @StateObject private var network = NetworkMonitor()


    private enum ActiveAlert: Identifiable {
        case signOut
        case deleteProfile
        var id: Int { hashValue }
    }

    @State private var activeAlert: ActiveAlert?
    @State private var isWorking: Bool = false
    @State private var errorMessage: String?
    @State private var lastSavedGoal: String = ""

    private let goals: [String] = [
        "Muskeln aufbauen",
        "Gewicht abnehmen",
        "Kraft steigern",
        "Routine aufbauen",
        "Fit bleiben",
        "sonstiges"
    ]

    private var displayName: String {
        let full = ([storedFirstName, storedLastName]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " "))
        return full.isEmpty ? "—" : full
    }

    private var displayEmail: String {
        let supa = auth.userEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        if !supa.isEmpty { return supa }
        if !storedEmail.isEmpty { return storedEmail }
        return "—"
    }

    var body: some View {
        List {
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

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .font(.footnote)
                }
            }

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
                    SettingsAboView()
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

            Section {
                HStack {
                    HStack(spacing: 0) {
                        Image(systemName: "target")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.secondary)
                    }

                    Text("Ziel")
                    Spacer()

                    Menu {
                        Picker("Ziel", selection: $storedGoal) {
                            ForEach(goals, id: \.self) { goal in
                                Text(goal).tag(goal)
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text(storedGoal.isEmpty ? "—" : storedGoal)
                            Image(systemName: "chevron.up.chevron.down")
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .contentShape(Rectangle())
                    }
                    .disabled(isWorking)
                }
            }

            Section {
                Button(role: .destructive) { activeAlert = .signOut } label: {
                    Text("Abmelden")
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .disabled(!network.isConnected || isWorking)
            }
        }
        .toolbar(.hidden, for: .tabBar)
        .listStyle(.insetGrouped)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { lastSavedGoal = storedGoal }
        .onChange(of: storedGoal) { _, newValue in
            guard newValue != lastSavedGoal else { return }
            lastSavedGoal = newValue
            Task { await updateGoal(newValue) }
        }
        .alert(item: $activeAlert) { alert in
            switch alert {
            case .signOut:
                return Alert(
                    title: Text("Abmelden?"),
                    message: Text("Du wirst abgemeldet und gelangst zurück zum Login."),
                    primaryButton: .destructive(Text("Abmelden")) {
                        Task { await signOut() }
                    },
                    secondaryButton: .cancel(Text("Abbrechen"))
                )

            case .deleteProfile:
                return Alert(
                    title: Text("Account wirklich löschen?"),
                    message: Text("Dein Account (Supabase) und alle lokalen App-Daten werden dauerhaft gelöscht. Das kann nicht rückgängig gemacht werden."),
                    primaryButton: .destructive(Text("Account löschen")) {
                        Task { await deleteProfile() }
                    },
                    secondaryButton: .cancel(Text("Abbrechen"))
                )
            }
        }
    }

    @MainActor
    private func updateGoal(_ newGoal: String) async {
        guard network.isConnected else {
            errorMessage = "Diese Aktion ist nur mit Internet möglich."
            return
        }

        errorMessage = nil
        isWorking = true
        defer { isWorking = false }

        onboardingGoal = newGoal

        do {
            let email = (displayEmail == "—") ? auth.userEmail : displayEmail

            try await auth.upsertProfile(
                email: email,
                firstName: storedFirstName,
                lastName: storedLastName,
                goal: newGoal
            )

            await auth.syncProfileFromBackendToLocal()
        } catch {
            errorMessage = "Ziel konnte nicht gespeichert werden: \(error.localizedDescription)"
        }
    }

    @MainActor
    private func signOut() async {
        guard network.isConnected else {
            errorMessage = "Zum Abmelden bitte Internet verbinden, damit deine Daten vorher synchronisiert werden."
            return
        }

        errorMessage = nil
        isWorking = true
        defer { isWorking = false }

        do {
            // Offline-first: vor lokalem Löschen MUSS der letzte Stand in Supabase sein.
            try await sync.flushOrThrow()

            await auth.signOut()
            store.deleteAllData()

            print("🚪 SettingsProfileView: signOut completed (cloud synced, local wiped)")
        } catch {
            print("❌ SettingsProfileView: signOut blocked (flush failed):", error)
            errorMessage = "Zum Abmelden bitte kurz Internet verbinden, damit nichts verloren geht.\n\nFehler: \(error.localizedDescription)"
        }
    }

    @MainActor
    private func deleteProfile() async {
        guard network.isConnected else {
            errorMessage = "Diese Aktion ist nur mit Internet möglich."
            return
        }

        errorMessage = nil
        isWorking = true
        defer { isWorking = false }

        do {
            try await auth.deleteAccountCompletely()
            store.deleteAllData()
            resetAppStateToFreshInstall()
        } catch {
            errorMessage = "Account konnte NICHT serverseitig gelöscht werden.\nFehler: \(error.localizedDescription)\n\nBitte erneut versuchen."
        }
    }

    private func resetAppStateToFreshInstall() {
        hasCompletedOnboarding = false
        hasCreatedAccount = false

        storedEmail = ""
        storedFirstName = ""
        storedLastName = ""
        storedGoal = ""
        onboardingGoal = ""
    }
}
