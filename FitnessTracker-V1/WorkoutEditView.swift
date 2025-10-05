import SwiftUI

struct WorkoutEditView: View {
    @EnvironmentObject var store: Store
    @EnvironmentObject private var router: Router
    @Environment(\.dismiss) private var dismiss
    @Environment(\.editMode) private var editMode

    let trainingID: UUID

    @State private var showingNewExercise = false

    // Titel-Editing
    @State private var isEditingTitle = false
    @State private var draftTitle = ""
    @FocusState private var titleFocused: Bool

    private var training: Training? {
        store.trainings.first(where: { $0.id == trainingID })
    }

    private var hasExercises: Bool {
        (training?.exercises.isEmpty == false)
    }

    var body: some View {
        ZStack {
            List {
                if let training {
                    // MARK: - Editierbarer Titel
                    Section {
                        Group {
                            if isEditingTitle {
                                TextField("Workout-Titel", text: $draftTitle)
                                    .font(.system(size: 24, weight: .bold))
                                    .textInputAutocapitalization(.words)
                                    .disableAutocorrection(true)
                                    .focused($titleFocused)
                                    .onAppear {
                                        draftTitle = training.title
                                        DispatchQueue.main.async { titleFocused = true }
                                    }
                                    .onSubmit { commitTitle() }
                            } else {
                                Text(training.title)
                                    .font(.system(size: 24, weight: .bold))
                                    .onTapGesture { isEditingTitle = true }
                            }
                        }
                        .padding(.vertical, 4)
                    } header: {
                        Text("WORKOUT-TITEL")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.secondary)
                            .textCase(nil)
                            .padding(.leading, 4)
                    }
                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))

                    // MARK: - Übungen
                    if hasExercises {
                        Section {
                            ForEach(training.exercises) { ex in
                                if editMode?.wrappedValue == .active {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(ex.name)
                                            .font(.system(size: 16, weight: .semibold))
                                        Text(setCountText(for: ex))
                                            .font(.system(size: 14))
                                            .foregroundColor(.secondary)
                                    }
                                } else {
                                    NavigationLink(value: Route.exerciseEdit(trainingID: trainingID, exerciseID: ex.id)) {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(ex.name)
                                                .font(.system(size: 16, weight: .semibold))
                                            Text(setCountText(for: ex))
                                                .font(.system(size: 14))
                                                .foregroundColor(.secondary)
                                        }
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
                            Text("ÜBUNGEN")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.secondary)
                                .textCase(nil)
                                .padding(.leading, 4)
                        } footer: {
                            addExerciseButton
                        }
                    } else {
                        // Keine Überschrift, nur der Add-Button
                        Section {
                            EmptyView()
                        } footer: {
                            addExerciseButton
                        }
                    }
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)

        // Top-Leiste
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                }
                .accessibilityLabel("Zurück")
            }
            if hasExercises {
                ToolbarItem(placement: .topBarTrailing) {
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
                            Text("Fertig").fontWeight(.semibold)
                        } else {
                            Image(systemName: "pencil")
                        }
                    }
                    .accessibilityLabel("Übungen bearbeiten")
                }
            }
        }

        // Untere Leiste: „Workout starten”
        .toolbar {
            ToolbarItem(placement: .bottomBar) {
                Button {
                    router.go(.workoutRun(trainingID: trainingID))
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                } label: {
                    Text("Workout starten")
                        .fontWeight(.semibold)
                }
            }
        }

        // AddExercise Sheet
        .sheet(isPresented: $showingNewExercise) {
            NavigationStack {
                AddExerciseView(trainingID: trainingID, afterSave: .dismiss)
                    .environmentObject(store)
            }
        }

        // Titel automatisch committen
        .onChange(of: titleFocused) { focused in
            if !focused && isEditingTitle { commitTitle() }
        }

        // Edit-Modus deaktivieren, wenn keine Übungen mehr
        .onChange(of: hasExercises) { available in
            if !available, editMode?.wrappedValue == .active {
                editMode?.wrappedValue = .inactive
            }
        }

        // Tap außerhalb: Fokus lösen -> commit
        .background(
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    if isEditingTitle {
                        titleFocused = false
                    }
                }
        )
    }

    // MARK: - Komponenten
    private var addExerciseButton: some View {
        Button { showingNewExercise = true } label: {
            Label("Übung hinzufügen", systemImage: "plus")
                .fontWeight(.semibold)
        }
        .labelStyle(.titleAndIcon)
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top, 8)
    }

    // MARK: - Satz-Anzeige-Logik
    private func setCountText(for exercise: Exercise) -> String {
        let count = exercise.sets.count
        if count == 1 {
            return "1 Satz"
        } else {
            return "\(count) Sätze"
        }
    }

    // MARK: - Titel speichern
    private func commitTitle() {
        let new = draftTitle.trimmingCharacters(in: .whitespacesAndNewlines)
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
