import SwiftUI

struct WorkoutView: View {
    @EnvironmentObject var store: Store
    @StateObject private var router = Router()

    @State private var showingNew = false
    @State private var newTitle = ""

    // Löschen-Bestätigung (unverändert)
    @State private var showDeleteAlert = false
    @State private var pendingDeleteID: UUID? = nil

    var body: some View {
        NavigationStack(path: $router.path) {
            List {
                if store.trainings.isEmpty {
                    Section {
                        Text("Tippe oben rechts auf „+“ um ein Workout anzulegen.")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    ForEach(store.trainings) { t in
                        Section {
                            // Jetzt: Direkter Sprung zur Inspect-View (kein Start-Alert mehr hier)
                            Button {
                                router.go(.workoutInspect(trainingID: t.id))
                            } label: {
                                HStack {
                                    Text(t.title)
                                        .font(.headline)
                                        .padding(.vertical, 8)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundStyle(.tertiary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
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
                    }
                }
            }
            .listStyle(.insetGrouped)
            .listSectionSpacing(.compact)
            .navigationTitle("Workouts")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingNew = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Neues Training")
                }
            }
            // Navigation inkl. neuer Inspect-Route
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .workoutInspect(let id):
                    WorkoutInspectView(trainingID: id)
                        .environmentObject(store)

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
        .environmentObject(router)

        // Neues Workout anlegen (unverändert)
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
                        .foregroundColor(.blue)
                    }
                }
            }
            .presentationDetents([.height(220)])
        }

        // Sicherheitsabfrage vor dem Löschen (unverändert)
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
}
