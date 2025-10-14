import SwiftUI

struct WorkoutView: View {
    @EnvironmentObject var store: Store
    @StateObject private var router = Router()   // Routing unverändert

    @State private var showingNew = false
    @State private var newTitle = ""

    // Löschen-Bestätigung (unverändert)
    @State private var showDeleteAlert = false
    @State private var pendingDeleteID: UUID? = nil
    
    @State private var showStartAlert = false
    @State private var pendingStartID: UUID? = nil


    var body: some View {
        NavigationStack(path: $router.path) {
            List {
                if store.trainings.isEmpty {
                    Section {
                        Text("Tippe oben rechts auf „+“ um ein Workout anzulegen.")
                            .foregroundStyle(.secondary)
                        
                        /*Text("Tippe oben rechts auf „+“, um ein Training anzulegen.")
                            .font(.subheadline)
                            .foregroundStyle(.tertiary)*/
                    }
                } else {
                    ForEach(store.trainings) { t in
                        Section {
                            // Statt direktem NavigationLink: erst bestätigen lassen
                            Button {
                                if t.exercises.isEmpty {
                                        // direkt weiterleiten ohne Alert
                                        router.go(.workoutRun(trainingID: t.id))
                                } else {
                                    pendingStartID = t.id
                                    showStartAlert = true
                                }
                            } label: {
                                HStack {
                                    Text(t.title)
                                        .font(.headline)
                                        .padding(.vertical, 8) // optional: größere Hit-Area
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundStyle(.tertiary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading) // nimmt die ganze Zellbreite
                                .contentShape(Rectangle()) // macht die ganze Fläche tappbar
                            }
                            .buttonStyle(.plain)


                            // Long-Press: Bearbeiten / Löschen (unverändert)
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
            // Navigation bleibt wie vorher über Route:
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
        .environmentObject(router)

        // Sheet zum Anlegen eines neuen Trainings (unverändert)
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
        .alert("\(store.trainings.first(where: { $0.id == pendingStartID })?.title ?? "Workout")-Workout starten?", isPresented: $showStartAlert) {
            Button("Abbrechen", role: .cancel) {
                pendingStartID = nil
            }
            Button("Starten") {
                if let id = pendingStartID {
                    // Navigation wie bisher per Router/Route
                    router.go(.workoutRun(trainingID: id))

                }
                pendingStartID = nil
            }
            .keyboardShortcut(.defaultAction) // macht den Button blau (iOS 26 UI)
        } message: {
            Text("Mach dich bereit zum Trainieren")
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
