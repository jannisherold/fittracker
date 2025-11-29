import SwiftUI

struct WorkoutView: View {
    @EnvironmentObject var store: Store
    @StateObject private var router = Router()
    @Environment(\.editMode) private var editMode          // ⬅️ EditMode für Reorder
    
    @State private var showingNew = false
    @State private var newTitle = ""
    
    // Löschen-Bestätigung (unverändert)
    @State private var showDeleteAlert = false
    @State private var pendingDeleteID: UUID? = nil
    
    var body: some View {
        NavigationStack(path: $router.path) {
            ZStack {
                List {
                    if store.trainings.isEmpty {
                        Section {
                            Text("Tippe oben links auf + um ein Workout anzulegen.")
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Section {
                            ForEach(store.trainings) { t in
                                
                                if editMode?.wrappedValue == .active {
                                    
                                    
                                    Text(t.title)
                                        .font(.headline)
                                        .padding(.vertical, 8)
                                    
                                    
                                    
                                } else {
                                    NavigationLink(value: Route.workoutInspect(trainingID: t.id)) {
                                        
                                        Text(t.title)
                                            .font(.headline)
                                            .padding(.vertical, 8)
                                    }
                                    
                                    
                                }
                                
                                
                                
                            }
                            // ⬇️ Reorder-Funktion für Workouts
                            .onMove { indices, newOffset in
                                store.moveTraining(from: indices, to: newOffset)
                            }
                        }
                    }
                }
                
                
            }
            //.listStyle(.insetGrouped)
            //.listSectionSpacing(.compact)
            .navigationTitle("Workouts")
            .navigationBarTitleDisplayMode(.large)
            
            // Toolbar oben: + links, Edit/Sortieren rechts
            .toolbar {
                // Plus-Button nach links gewandert
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingNew = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Neues Training")
                }
                
                // Edit-/Reorder-Button rechts
                ToolbarItem(placement: .topBarTrailing) {
                    if !store.trainings.isEmpty {
                        Button {
                            withAnimation {
                                if editMode?.wrappedValue == .active {
                                    editMode?.wrappedValue = .inactive
                                } else {
                                    editMode?.wrappedValue = .active
                                }
                            }
                        } label: {
                            if editMode?.wrappedValue == .active {
                                Text("Fertig")
                                    .fontWeight(.semibold)
                            } else {
                                Image(systemName: "list.bullet")
                            }
                        }
                        .accessibilityLabel("Workouts bearbeiten")
                    }
                }
            }
            
            // Navigation inkl. Inspect-/Edit-/Run-Routes
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
