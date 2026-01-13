import SwiftUI
import Network
import UIKit

@MainActor
final class NetworkMonitor: ObservableObject {
    @Published private(set) var isConnected: Bool = true

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.isConnected = (path.status == .satisfied)
            }
        }
        monitor.start(queue: queue)
    }

    deinit { monitor.cancel() }
}

struct SettingsPersonalDataView: View {
    @EnvironmentObject private var store: Store
    @EnvironmentObject private var auth: SupabaseAuthManager

    @AppStorage("userEmail") private var storedEmail: String = ""
    @AppStorage("userFirstName") private var storedFirstName: String = ""
    @AppStorage("userLastName") private var storedLastName: String = ""
    @AppStorage("userGoal") private var storedGoal: String = ""
    @AppStorage("userContactEmail") private var storedContactEmail: String = ""
    @AppStorage("userMarketingOptIn") private var storedMarketingOptIn: Bool = false
    @AppStorage("onboardingGoal") private var onboardingGoal: String = ""
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @AppStorage("hasCreatedAccount") private var hasCreatedAccount: Bool = false
    @State private var isSavingMarketingOptIn = false


    @StateObject private var network = NetworkMonitor()

    @State private var isEditingName = false
    @State private var firstDraft = ""
    @State private var lastDraft = ""

    @State private var isEditingContactEmail = false
    @State private var contactEmailDraft = ""

    @State private var isWorking = false
    @State private var errorMessage: String?

    @State private var showResetBodyweightConfirm = false
    @State private var showDeleteAccountConfirm = false

    private enum NameField: Hashable {
        case first
        case last
    }
    @FocusState private var focusedNameField: NameField?

    private struct NameValidationResult {
        let value: String
        let error: String?
    }

    private func normalizeNameInput(_ s: String) -> String {
        // Trim + Mehrfachspaces reduzieren
        let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
        // Split auf Whitespaces/Newlines und wieder mit einem Space zusammenfügen
        let parts = trimmed.split(whereSeparator: { $0.isWhitespace || $0.isNewline })
        return parts.joined(separator: " ")
    }

    private func validateNameField(_ raw: String, fieldLabel: String) -> NameValidationResult {
        let value = normalizeNameInput(raw)

        // Länge
        if value.isEmpty {
            return .init(value: value, error: "\(fieldLabel) darf nicht leer sein.")
        }
        if value.count > 50 {
            return .init(value: value, error: "\(fieldLabel) ist zu lang (max. 50 Zeichen).")
        }

        // Zeichen erlauben: Buchstaben + Space + - + ' + ’
        // \p{L} = alle Unicode-Letters (inkl. Umlaute, Akzente, nicht-lateinische Alphabete)
        // Wir erlauben außerdem Leerzeichen, Bindestrich, Apostroph.
        let pattern = #"^[\p{L}][\p{L}\s\-'\u{2019}]*$"#

        if value.range(of: pattern, options: [.regularExpression]) == nil {
            return .init(
                value: value,
                error: "\(fieldLabel) enthält unzulässige Zeichen. Erlaubt sind nur Buchstaben, Leerzeichen, Bindestrich und Apostroph."
            )
        }

        // Optional: keine doppelten Sonderzeichen am Ende/Anfang (z.B. "-" am Ende)
        if let first = value.first, let last = value.last {
            let forbiddenEdgeChars: Set<Character> = ["-", "'", "’", " "]
            if forbiddenEdgeChars.contains(first) || forbiddenEdgeChars.contains(last) {
                return .init(value: value, error: "\(fieldLabel) darf nicht mit Leerzeichen, Bindestrich oder Apostroph beginnen/enden.")
            }
        }

        return .init(value: value, error: nil)
    }

    private var displayEmail: String {
        let supa = auth.userEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        if !supa.isEmpty { return supa }
        if !storedEmail.isEmpty { return storedEmail }
        return ""
    }

    private var displayContactEmail: String {
        let v = storedContactEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        return v.isEmpty ? "—" : v
    }

    private var displayName: String {
        let full = ([storedFirstName, storedLastName].filter { !$0.isEmpty }).joined(separator: " ")
        return full.isEmpty ? "—" : full
    }

    var body: some View {
        List {
            Section {
                Button {
                    firstDraft = storedFirstName
                    lastDraft = storedLastName
                    isEditingName = true
                } label: {
                    HStack {
                        Text("Name")
                        Spacer()
                        Text(displayName)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        Image(systemName: "chevron.right")
                            .font(.footnote)
                            .foregroundStyle(.tertiary)
                    }
                }
                .disabled(!network.isConnected || isWorking)

                Button {
                    contactEmailDraft = storedContactEmail.isEmpty ? displayEmail : storedContactEmail
                    isEditingContactEmail = true
                } label: {
                    HStack {
                        Text("Kontakt E-Mail")
                        Spacer()
                        Text(displayContactEmail)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        Image(systemName: "chevron.right")
                            .font(.footnote)
                            .foregroundStyle(.tertiary)
                    }
                }
                .disabled(!network.isConnected || isWorking)

                Toggle(isOn: Binding(
                    get: { storedMarketingOptIn },
                    set: { newValue in
                        let previous = storedMarketingOptIn
                        storedMarketingOptIn = newValue
                        Task { await saveMarketingOptIn(newValue, previous: previous) }
                    }
                )) {
                    HStack(spacing: 8) {
                        Text("Update-E-Mails")
                        if isSavingMarketingOptIn {
                            ProgressView()
                                .controlSize(.small)
                        }
                    }
                }
                .disabled(!network.isConnected || isSavingMarketingOptIn || isWorking)

            } footer: {
                if !network.isConnected {
                    Text("Du bist offline. Änderungen sind nur mit Internetverbindung möglich.")
                }
            }

            Section {
                Button(role: .destructive) {
                    showResetBodyweightConfirm = true
                } label: {
                    HStack {
                        Text("Körpergewicht zurücksetzen")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.footnote)
                            .foregroundStyle(.tertiary)
                    }
                }
                .disabled(!network.isConnected || isWorking)
            } footer: {
                Text("Löscht deine gespeicherten Körpergewichtsdaten lokal. (Wenn du später auch Supabase-Reset willst, setzen wir das im nächsten Schritt um.)")
            }

            Section {
                Button(role: .destructive) {
                    showDeleteAccountConfirm = true
                } label: {
                    HStack {
                        Text("Account löschen")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.footnote)
                            .foregroundStyle(.tertiary)
                    }
                }
                .disabled(!network.isConnected || isWorking)
            } footer: {
                Text("Account löschen ist nur online möglich.")
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .font(.footnote)
                }
            }
        }
        .navigationTitle("Persönliche Daten")
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if isWorking { ProgressView() }
        }
        .confirmationDialog(
            "Körpergewicht zurücksetzen?",
            isPresented: $showResetBodyweightConfirm,
            titleVisibility: .visible
        ) {
            Button("Zurücksetzen", role: .destructive) {
                store.resetBodyweightEntries()
            }
            Button("Abbrechen", role: .cancel) {}
        }
        .confirmationDialog(
            "Account wirklich löschen?",
            isPresented: $showDeleteAccountConfirm,
            titleVisibility: .visible
        ) {
            Button("Account löschen", role: .destructive) {
                Task { await deleteAccount() }
            }
            Button("Abbrechen", role: .cancel) {}
        } message: {
            Text("Dies löscht deinen Supabase-Account und alle lokalen Daten dauerhaft.")
        }
        .sheet(isPresented: $isEditingName) {
            NavigationStack {
                Form {
                    Section {
                        TextField("Vorname", text: $firstDraft)
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled()
                            .submitLabel(.next)
                            .focused($focusedNameField, equals: .first)
                            .onSubmit { focusedNameField = .last }

                        TextField("Nachname", text: $lastDraft)
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled()
                            .submitLabel(.done)
                            .focused($focusedNameField, equals: .last)
                            .onSubmit { focusedNameField = nil }
                    }
                }
                .scrollDismissesKeyboard(.immediately)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Abbrechen") { isEditingName = false }
                            .disabled(isWorking)
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Speichern") {
                            Task { await saveName() }
                        }
                        .foregroundColor(.blue)
                        .disabled(
                            isWorking ||
                            !network.isConnected ||
                            firstDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        )
                    }
                }
                .onAppear {
                    DispatchQueue.main.async {
                        focusedNameField = .first
                    }
                }
            }
        }
        .sheet(isPresented: $isEditingContactEmail) {
            NavigationStack {
                Form {
                    Section {
                        TextField("Kontakt E-Mail", text: $contactEmailDraft)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                }
                .scrollDismissesKeyboard(.immediately)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Abbrechen") { isEditingContactEmail = false }
                            .disabled(isWorking)
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Speichern") {
                            Task { await saveContactEmail() }
                        }
                        .foregroundColor(.blue)
                        .disabled(
                            isWorking ||
                            !network.isConnected ||
                            contactEmailDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        )
                    }
                }
            }
        }
    }

    @MainActor
    private func saveName() async {
        guard network.isConnected else { return }

        errorMessage = nil
        isWorking = true
        defer { isWorking = false }

        let firstCheck = validateNameField(firstDraft, fieldLabel: "Vorname")
        if let err = firstCheck.error {
            errorMessage = err
            return
        }

        let lastNormalized = normalizeNameInput(lastDraft)
        var ln = ""
        if !lastNormalized.isEmpty {
            let lastCheck = validateNameField(lastDraft, fieldLabel: "Nachname")
            if let err = lastCheck.error {
                errorMessage = err
                return
            }
            ln = lastCheck.value
        }

        let fn = firstCheck.value

        do {
            let goal = storedGoal.isEmpty ? (onboardingGoal.isEmpty ? "Überspringen" : onboardingGoal) : storedGoal
            let email = displayEmail.isEmpty ? auth.userEmail : displayEmail

            try await auth.upsertProfile(email: email, firstName: fn, lastName: ln, goal: goal)
            await auth.syncProfileFromBackendToLocal()

            isEditingName = false
        } catch {
            errorMessage = "Name konnte nicht gespeichert werden: \(error.localizedDescription)"
        }
    }
    
    private func isPlausibleEmail(_ input: String) -> Bool {
        let email = input.trimmingCharacters(in: .whitespacesAndNewlines)

        // Basic constraints
        if email.isEmpty || email.count > 254 { return false }
        if email.contains(" ") { return false }
        if email.contains("..") { return false }

        // Exactly one "@"
        let parts = email.split(separator: "@", omittingEmptySubsequences: false)
        if parts.count != 2 { return false }

        let local = String(parts[0])
        let domain = String(parts[1])

        // Local + domain must be non-empty
        if local.isEmpty || domain.isEmpty { return false }

        // Local part max length (common constraint)
        if local.count > 64 { return false }

        // Domain must contain a dot and a plausible TLD
        if !domain.contains(".") { return false }

        // Quick regex (conservative, not RFC-perfect by design)
        let pattern = #"^[A-Z0-9a-z._%+\-']+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$"#
        return email.range(of: pattern, options: .regularExpression) != nil
    }


    @MainActor
    private func saveContactEmail() async {
        guard network.isConnected else { return }

        errorMessage = nil
        isWorking = true
        defer { isWorking = false }

        let mail = contactEmailDraft.trimmingCharacters(in: .whitespacesAndNewlines)

        guard isPlausibleEmail(mail) else {
            errorMessage = "Bitte gib eine gültige Kontakt E-Mail ein."
            return
        }


        do {
            try await auth.updateContactPreferences(contactEmail: mail, marketingOptIn: nil)
            isEditingContactEmail = false
        } catch {
            errorMessage = "Kontakt E-Mail konnte nicht gespeichert werden: \(error.localizedDescription)"
        }
    }

    @MainActor
    private func saveMarketingOptIn(_ newValue: Bool, previous: Bool) async {
        guard network.isConnected else {
            storedMarketingOptIn = previous
            return
        }

        errorMessage = nil
        isSavingMarketingOptIn = true
        defer { isSavingMarketingOptIn = false }

        do {
            try await auth.updateContactPreferences(contactEmail: nil, marketingOptIn: newValue)
        } catch {
            storedMarketingOptIn = previous
            errorMessage = "Einstellung konnte nicht gespeichert werden: \(error.localizedDescription)"
        }
    }


    @MainActor
    private func deleteAccount() async {
        guard network.isConnected else { return }

        errorMessage = nil
        isWorking = true
        defer { isWorking = false }

        do {
            try await auth.deleteAccountCompletely()
            store.deleteAllData()

            // AppState reset (wie in SettingsProfileView)
            hasCompletedOnboarding = false
            hasCreatedAccount = false
            storedEmail = ""
            storedFirstName = ""
            storedLastName = ""
            storedGoal = ""
            storedContactEmail = ""
            storedMarketingOptIn = false
            onboardingGoal = ""
        } catch {
            errorMessage = "Account konnte nicht gelöscht werden: \(error.localizedDescription)"
        }
    }
}
