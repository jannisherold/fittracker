import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: Store

    @StateObject private var router = Router()   // zentraler Router/Path

    @State private var showingNew = false
    @State private var newTitle = ""

    // Für die Lösch-Bestätigung
    @State private var showDeleteAlert = false
    @State private var pendingDeleteID: UUID? = nil   // Training.ID (UUID)

    var body: some View {
        NavigationStack(path: $router.path) {
            List {
                ForEach(store.trainings) { t in
                    // Tippen startet das Workout (Route)
                    NavigationLink(t.title, value: Route.workoutRun(trainingID: t.id))

                    // Long-Press Menü: Bearbeiten + Löschen (mit Bestätigung)
                    .contextMenu {
                        NavigationLink(value: Route.workoutEdit(trainingID: t.id)) {
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
                    Button { showingNew = true } label: { Image(systemName: "plus") }
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

            // Route -> konkrete Views
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .workoutRun(let id):
                    WorkoutRunView(trainingID: id)
                        .environmentObject(store)
                case .workoutEdit(let id):
                    WorkoutEditView(trainingID: id)
                        .environmentObject(store)
                case .exerciseEdit(let tid, let eid):
                    ExerciseEditView(trainingID: tid, exerciseID: eid)
                        .environmentObject(store)
                case .addExercise(let tid):
                    AddExerciseView(trainingID: tid, afterSave: .goToEdit)
                        .environmentObject(store)
                }
            }
        }
        .environmentObject(router) // Router global verfügbar

        // Sheet zum Anlegen eines neuen Trainings (wie gehabt)
        .sheet(isPresented: $showingNew) {
            NavigationStack {
                Form {
                    TextField("Titel (z. B. Oberkörper, Unterkörper, ...)", text: $newTitle)
                }
                .scrollDismissesKeyboard(.immediately)
                .onTapGesture { hideKeyboard() }
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
