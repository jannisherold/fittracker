import SwiftUI

struct WorkoutEditView: View {
    @EnvironmentObject var store: Store
    let trainingID: UUID

    @State private var showingNewExercise = false
    @Environment(\.editMode) private var editMode     // ← für eigenen Edit-Schalter
    
    @State private var isEditingTitle = false
    @State private var draftTitle = ""
    @FocusState private var titleFocused: Bool


    private var training: Training? {
        store.trainings.first(where: { $0.id == trainingID })
    }

    var body: some View {
        List {
            if let training {
                // -- Editierbarer Titel --
                Section {
                    Group {
                        if isEditingTitle {
                            TextField("Workout-Titel", text: $draftTitle)
                                .font(.system(size: 34, weight: .bold))      // Optik wie großer Titel
                                .textInputAutocapitalization(.words)
                                .disableAutocorrection(true)
                                .focused($titleFocused)
                                .onAppear {
                                    draftTitle = training.title
                                    // Tastatur sofort öffnen
                                    DispatchQueue.main.async { titleFocused = true }
                                }
                                .onSubmit { commitTitle() }
                        } else {
                            Text(training.title)
                                .font(.system(size: 34, weight: .bold))
                                .onTapGesture {
                                    isEditingTitle = true
                                }
                        }
                    }
                    .padding(.vertical, 4)
                }
                // etwas enger an den Rand, sieht wie ein Titel aus
                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                // -- Ende: Editierbarer Titel --

                Section("ÜBUNGEN") {
                    ForEach(training.exercises) { ex in
                        if editMode?.wrappedValue == .active {
                            // Edit-Modus: kein Chevron, dafür erscheint der Drag-Handle automatisch
                            Text(ex.name)
                        } else {
                            // Normal: Tippen öffnet die Detailansicht
                            NavigationLink(ex.name) {
                                ExerciseDetailView(trainingID: trainingID, exerciseID: ex.id)
                            }
                        }
                    }
                    .onMove { indices, newOffset in
                        store.moveExercise(in: trainingID, from: indices, to: newOffset)
                    }
                    .onDelete { offsets in
                        store.deleteExercise(in: trainingID, at: offsets)
                    }

                
                }
            }
        }
        .navigationTitle("")     // wir zeigen unten unseren eigenen großen Titel
        .navigationBarTitleDisplayMode(.inline)
        // 🔽 Leiste direkt unter dem großen Titel
        .safeAreaInset(edge: .top) { headerControls }
        // (Keine Toolbar mehr für Edit/+)
        
        .sheet(isPresented: $showingNewExercise) {
            AddExerciseView(trainingID: trainingID, afterSave: .dismiss)
                .environmentObject(store)
        }
        
    }

    // MARK: - Header unter Titel
    private var headerControls: some View {
        HStack {
            Button {
                // Toggle Edit-Modus der List
                withAnimation {
                    if editMode?.wrappedValue == .active {
                        editMode?.wrappedValue = .inactive
                    } else {
                        editMode?.wrappedValue = .active
                    }
                }
            } label: {
                Label(editMode?.wrappedValue == .active ? "Fertig" : "Übungen bearbeiten",
                      systemImage: "pencil")
            }

            Spacer()

            Button {
                showingNewExercise = true
            } label: {
                Label("Übung", systemImage: "plus")
                    .fontWeight(.semibold)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
        //.background(.ultraThinMaterial)   // dezente Fläche unter dem Titel
        //.shadow(radius: 0.5)
    }

    // MARK: - Titel speichern
    private func commitTitle() {
        let new = draftTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        // Leer? -> Abbrechen, zurück zu Anzeige
        guard !new.isEmpty else {
            isEditingTitle = false
            return
        }
        if let idx = store.trainings.firstIndex(where: { $0.id == trainingID }) {
            store.trainings[idx].title = new
        }
        isEditingTitle = false
    }

}
