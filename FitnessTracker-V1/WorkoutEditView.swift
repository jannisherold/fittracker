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
        ZStack {
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
                    
                    Section {
                        ForEach(training.exercises) { ex in
                            if editMode?.wrappedValue == .active {
                                Text(ex.name)
                            } else {
                                NavigationLink {
                                    ExerciseDetailView(trainingID: trainingID, exerciseID: ex.id)
                                } label: {
                                    Text(ex.name)
                                }
                            }
                        }
                        .onMove { indices, newOffset in
                            store.moveExercise(in: trainingID, from: indices, to: newOffset)
                        }
                        .onDelete { offsets in
                            store.deleteExercise(in: trainingID, at: offsets)
                        }
                    } header: {
                        HStack {
                            Text("ÜBUNGEN")
                                .font(.system(size: 15, weight: .semibold))   // größer
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            Button {
                                withAnimation {
                                    if editMode?.wrappedValue == .active {
                                        editMode?.wrappedValue = .inactive
                                    } else {
                                        editMode?.wrappedValue = .active
                                    }
                                }
                            } label: {
                                // 👉 Nur Icon im Default, nur Text "Fertig" im Edit-Modus
                                if editMode?.wrappedValue == .active {
                                    Text("Fertig")
                                        .fontWeight(.semibold)
                                        .foregroundColor(.blue)
                                } else {
                                    Image(systemName: "pencil")
                                        .foregroundColor(.blue)
                                }
                            }
                            .font(.system(size: 18, weight: .semibold))
                            .buttonStyle(.plain) // optisch wie im Mockup
                            .accessibilityLabel("Übungen bearbeiten")
                            .contentShape(Rectangle())
                            .padding(.vertical, 8)
                            
                        }
                        .textCase(nil)
                        .padding(.horizontal, 0)
                        .padding(.leading, 4)
                        .padding(.trailing, 4)
                        
                    }
                    
                    
                    Section {
                        HStack {
                            Spacer()
                            Button {
                                showingNewExercise = true
                            } label: {
                                Label("Übung hinzufügen", systemImage: "plus")
                                    .fontWeight(.semibold)
                            }
                            .labelStyle(.titleAndIcon)
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                    // sorgt dafür, dass die Reihe wie „frei schwebend“ wirkt
                    .listRowBackground(Color.clear)
                    
                }
            }
            
            
            .navigationTitle("")     // wir zeigen unten unseren eigenen großen Titel
            .navigationBarTitleDisplayMode(.inline)
            
            .sheet(isPresented: $showingNewExercise) {
                AddExerciseView(trainingID: trainingID, afterSave: .dismiss)
                    .environmentObject(store)
            }
            .onChange(of: titleFocused) { focused in
                if !focused && isEditingTitle {
                    commitTitle()
                }
            }
        }
        .background(
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    if isEditingTitle {
                        titleFocused = false   // beendet Edit und speichert via commitTitle()
                    }
                }
        )
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
