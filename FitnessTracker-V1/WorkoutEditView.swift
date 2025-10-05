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

    var body: some View {
        ZStack {
            List {
                if let training {
                    // MARK: - Editierbarer Titel
                    Section {
                        Group {
                            if isEditingTitle {
                                TextField("Workout-Titel", text: $draftTitle)
                                    .font(.system(size: 34, weight: .bold))
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
                                    .font(.system(size: 34, weight: .bold))
                                    .onTapGesture { isEditingTitle = true }
                            }
                        }
                        .padding(.vertical, 4)
                    } header: {
                        Text("TITEL")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.secondary)
                            .textCase(nil)
                            .padding(.leading, 4)
                    }
                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))

                    // MARK: - Übungen
                    Section {
                        ForEach(training.exercises) { ex in
                            if editMode?.wrappedValue == .active {
                                Text(ex.name)
                                    .font(.system(size: 16, weight: .semibold))
                            } else {
                                NavigationLink(value: Route.exerciseEdit(trainingID: trainingID, exerciseID: ex.id)) {
                                    Text(ex.name)
                                        .font(.system(size: 16, weight: .semibold))
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
                        // Nur Überschrift – der Bearbeiten-Button ist jetzt in der Toolbar (rechts)
                        Text("ÜBUNGEN")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.secondary)
                            .textCase(nil)
                            .padding(.leading, 4)
                    }

                    // MARK: - Übung hinzufügen
                    Section {
                        HStack {
                            Spacer()
                            Button { showingNewExercise = true } label: {
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
                    .listRowBackground(Color.clear)
                }
            }
        }
        .navigationTitle(training?.title ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)

        // Top-Leiste: links zurück, rechts Bearbeiten-Stift (toggt Edit-Mode)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    // Zur vorherigen View zurück (WorkoutView ODER WorkoutRunView)
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                }
                .accessibilityLabel("Zurück")
            }

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

        // Untere Leiste: „Workout starten“ wie in WorkoutRunView die .bottomBar
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

        // AddExercise in Sheet mit NavigationStack (für Titel/Buttons)
        .sheet(isPresented: $showingNewExercise) {
            NavigationStack {
                AddExerciseView(trainingID: trainingID, afterSave: .dismiss)
                    .environmentObject(store)
            }
        }

        // Titel automatisch committen, wenn Fokus verloren geht
        .onChange(of: titleFocused) { focused in
            if !focused && isEditingTitle { commitTitle() }
        }

        // Tap außerhalb: Fokus lösen -> commit
        .background(
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    if isEditingTitle {
                        titleFocused = false // löst commitTitle() aus
                    }
                }
        )
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
