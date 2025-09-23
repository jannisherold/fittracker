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
            ZStack {
                // Hintergrund wie im Mockup
                Color(.systemGray6).ignoresSafeArea()

                VStack(alignment: .leading, spacing: 16) {

                    // 1) Oben zentriert: "progress."
                    Text("progress.")
                        .font(.title2.weight(.semibold))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 8)

                    // 2) Zeile mit blauem "Workouts" + schwarzem Plus rechts
                    HStack(alignment: .firstTextBaseline) {
                        Text("Workouts")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(Color(.systemBlue))
                            .accessibilityAddTraits(.isHeader)

                        Spacer()

                        Button {
                            showingNew = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.title2.weight(.semibold))
                                .foregroundColor(.primary)
                                .padding(.horizontal, 2)
                                .contentShape(Rectangle())
                        }
                        .accessibilityLabel("Neues Training")
                    }
                    .padding(.top, 4)

                    // 3) Karten-Liste mit Schatten
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(store.trainings) { t in
                                NavigationLink(value: Route.workoutRun(trainingID: t.id)) {
                                    HStack {
                                        Text(t.title)
                                            .font(.body)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.primary)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.headline)
                                            .foregroundColor(.gray.opacity(0.5))
                                    }
                                    .padding(.vertical, 14)
                                    .padding(.horizontal, 18)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .fill(Color.white)
                                            //.shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 0)
                                    )
                                }
                                // Long-Press: Bearbeiten / Löschen (wie vorher)
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
                        .padding(.top, 4)
                    }

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 20)
            }
            // Routing bleibt identisch
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
            // Wichtig: Keine .navigationTitle / .toolbar mehr, Header ist nun custom
        }
        .environmentObject(router) // Router global verfügbar

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
