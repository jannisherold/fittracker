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

struct FirstResponderTextField: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String
    var capitalization: UITextAutocapitalizationType = .words

    func makeUIView(context: Context) -> UITextField {
        let tf = UITextField(frame: .zero)
        tf.delegate = context.coordinator
        tf.placeholder = placeholder
        tf.text = text
        tf.clearButtonMode = .whileEditing
        tf.autocapitalizationType = capitalization
        tf.autocorrectionType = .no
        tf.returnKeyType = .done
        tf.font = UIFont.systemFont(ofSize: 22, weight: .regular)

        DispatchQueue.main.async { tf.becomeFirstResponder() }
        return tf
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        if uiView.text != text { uiView.text = text }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UITextFieldDelegate {
        let parent: FirstResponderTextField
        init(_ parent: FirstResponderTextField) { self.parent = parent }

        func textFieldDidChangeSelection(_ textField: UITextField) {
            parent.text = textField.text ?? ""
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            textField.resignFirstResponder()
            return true
        }
    }
}

struct SettingsPersonalDataView: View {
    @EnvironmentObject private var store: Store
    @EnvironmentObject private var auth: SupabaseAuthManager

    @AppStorage("userEmail") private var storedEmail: String = ""
    @AppStorage("userFirstName") private var storedFirstName: String = ""
    @AppStorage("userLastName") private var storedLastName: String = ""
    @AppStorage("userGoal") private var storedGoal: String = ""
    @AppStorage("onboardingGoal") private var onboardingGoal: String = ""
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @AppStorage("hasCreatedAccount") private var hasCreatedAccount: Bool = false

    @StateObject private var network = NetworkMonitor()

    @State private var isEditingName = false
    @State private var firstDraft = ""
    @State private var lastDraft = ""

    @State private var isWorking = false
    @State private var errorMessage: String?

    @State private var showResetBodyweightConfirm = false
    @State private var showDeleteAccountConfirm = false

    private var displayEmail: String {
        let supa = auth.userEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        if !supa.isEmpty { return supa }
        if !storedEmail.isEmpty { return storedEmail }
        return ""
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
                VStack(spacing: 14) {
                    VStack(spacing: 10) {
                        FirstResponderTextField(text: $firstDraft, placeholder: "Vorname")
                            .frame(height: 44)
                            .padding(.horizontal, 14)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                        FirstResponderTextField(text: $lastDraft, placeholder: "Nachname")
                            .frame(height: 44)
                            .padding(.horizontal, 14)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)

                    Text("Apple liefert Vor- und Nachname oft nur beim ersten Login. Deshalb pflegen wir sie hier separat.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 16)

                    Spacer()
                }
                .navigationTitle("Name ändern")
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
                        .disabled(isWorking || !network.isConnected || firstDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
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

        let fn = firstDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        let ln = lastDraft.trimmingCharacters(in: .whitespacesAndNewlines)

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
            onboardingGoal = ""
        } catch {
            errorMessage = "Account konnte nicht gelöscht werden: \(error.localizedDescription)"
        }
    }
}
