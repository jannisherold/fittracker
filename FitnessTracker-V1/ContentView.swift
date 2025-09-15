import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: Store

    @State private var showingNew = false
    @State private var newTitle = ""

    // Für die Lösch-Bestätigung
    @State private var showDeleteAlert = false
    @State private var pendingDeleteID: UUID? = nil   // Training.ID (UUID)

    var body: some View {
        NavigationStack {
            List {
                ForEach(store.trainings) { t in
                    // Standard: Tippen startet das Workout
                    NavigationLink(t.title) {
                        WorkoutRunView(trainingID: t.id)
                    }
                    // Long-Press Menü: Bearbeiten + Löschen (mit Bestätigung)
                    .contextMenu {
                        NavigationLink {
                            WorkoutDetailView(trainingID: t.id)
                        } label: {
                            Label("Bearbeiten", systemImage: "pencil")
                        }

                        Button(role: .destructive) {
                            pendingDeleteID = t.id
                            showDeleteAlert = true
                        } label: {
                            Label("Löschen", systemImage: "trash")
                        }
                    }
                }
                // 👉 kein .onDelete hier – Löschen erfolgt nur über Long-Press mit Alert
            }
            .navigationTitle("Workouts")
            .toolbar {
                // Nur noch der "+"-Button
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingNew = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Neues Training")
                }
            }
            // Sicherheitsabfrage vor dem Löschen
            .alert("Workout löschen?", isPresented: $showDeleteAlert) {
                Button("Löschen", role: .destructive) {
                    if let id = pendingDeleteID,
                       let idx = store.trainings.firstIndex(where: { $0.id == id }) {
                        store.deleteTraining(at: IndexSet(integer: idx))
                    }
                    pendingDeleteID = nil
                }
                Button("Abbrechen", role: .cancel) {
                    pendingDeleteID = nil
                }
            } message: {
                Text("Dieser Vorgang kann nicht rückgängig gemacht werden.")
            }
        }
        // Sheet zum Anlegen eines neuen Trainings
        .sheet(isPresented: $showingNew) {
            NavigationStack {
                Form {
                    TextField("Titel (z. B. Oberkörper, Unterkörper, ...)", text: $newTitle)
                }
                .navigationTitle("Workout anlegen")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Abbrechen") { showingNew = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Speichern") {
                            let t = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !t.isEmpty else { return }
                            store.addTraining(title: t)
                            newTitle = ""
                            showingNew = false
                        }
                        .disabled(newTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
            .presentationDetents([.height(220)])
        }
    }
}
