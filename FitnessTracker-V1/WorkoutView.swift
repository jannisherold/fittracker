import SwiftUI

struct WorkoutView: View {
    @EnvironmentObject var store: Store
    @StateObject private var router = Router()

    @State private var editMode: EditMode = .inactive

    @State private var showingNew = false
    @State private var newTitle = ""

    @State private var showDeleteAlert = false
    @State private var pendingDeleteID: UUID? = nil

    var body: some View {
        NavigationStack(path: $router.path) {
            ZStack {
                List {
                    if store.trainings.isEmpty {
                    
                            Section {
                                Text("Tippe auf + um ein Workout anzulegen.")
                                    .foregroundStyle(.secondary)
                            }
                            .listRowBackground(Color.clear)
                            //.padding(.vertical, 8)
                        
                        
                    } else {
                        Section {
                            ForEach(store.trainings) { t in
                                if editMode == .active {
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
                            .onMove { indices, newOffset in
                                store.moveTraining(from: indices, to: newOffset)
                            }
                            .onDelete { offsets in
                                if let index = offsets.first {
                                    let training = store.trainings[index]
                                    pendingDeleteID = training.id
                                    showDeleteAlert = true
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Workouts")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingNew = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Neues Training")
                }
                
                ToolbarItem(placement: .principal) {
                    
                  
                            Button {
                                // TODO: später Upgrade / Paywall öffnen
                                print("Upgrade tapped")
                            } label: {
                                HStack{
                                    Text("Upgrade")
                                        .font(.subheadline
                                        .weight(.semibold))
                                        

                                    Image(systemName: "sparkles")
                                        .font(.system(size: 12, weight: .semibold))
                                        //.foregroundColor(.secondary)
                                        //.frame(width: 28, alignment: .leading)
                                    
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 8)
                                .background(.blue.opacity(0.12))
                                .foregroundStyle(.blue)
                                .clipShape(Capsule())
                                
                                
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Upgraden")
                        
                    
                    /*
                        Button {
                            // TODO: später Upgrade / Paywall öffnen
                            print("Upgrade tapped")
                        } label: {
                            HStack{
                                Text("Upgraden")
                                    .fontWeight(.semibold)
                                Image(systemName: "sparkles")
                                
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color(.systemBlue))
                        //.tint(.blue)
                        //.buttonStyle(.plain) // wichtig, sonst wirkt er wie "nav title" / kann komisch getintet sein
                        .accessibilityLabel("Upgraden")
                     */
                    }

                ToolbarItem(placement: .topBarTrailing) {
                    // ✅ Nur noch Edit-Button (kein Profil hier)
                    if !store.trainings.isEmpty {
                        Button {
                            withAnimation {
                                editMode = (editMode == .active) ? .inactive : .active
                            }
                        } label: {
                            if editMode == .active {
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
            .environment(\.editMode, $editMode)
        }
        .environmentObject(router)

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
            Text("Dieser Vorgang kann nicht rückgängig gemacht werden. Alle Daten absolvierter Sessions werden unwiderruflich gelöscht.")
        }
    }
}

#Preview("WorkoutView – mit Upgrade Button") {
    let previewStore = Store.preview // siehe Extension unten

    NavigationStack {
        WorkoutView()
            .environmentObject(previewStore)
    }
}
