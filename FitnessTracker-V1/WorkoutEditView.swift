import SwiftUI

struct WorkoutEditView: View {
    @EnvironmentObject var store: Store
    @EnvironmentObject private var router: Router

    let trainingID: UUID

    @State private var showingNewExercise = false
    @Environment(\.editMode) private var editMode

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
                    }
                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))

                    // MARK: - Übungen
                    Section {
                        ForEach(training.exercises) { ex in
                            if editMode?.wrappedValue == .active {
                                Text(ex.name)
                            } else {
                                NavigationLink(value: Route.exerciseEdit(trainingID: trainingID, exerciseID: ex.id)) {
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
                                .font(.system(size: 15, weight: .semibold))
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
                            .buttonStyle(.plain)
                            .accessibilityLabel("Übungen bearbeiten")
                            .contentShape(Rectangle())
                            .padding(.vertical, 8)
                        }
                        .textCase(nil)
                        .padding(.horizontal, 0)
                        .padding(.leading, 4)
                        .padding(.trailing, 4)
                    }

                    // MARK: - Übung hinzufügen (blauer CTA)
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
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    // Egal woher: zurück in die Run-View dieses Workouts
                    router.setRoot([.workoutRun(trainingID: trainingID)])
                } label: {
                    Image(systemName: "chevron.left")
                }
                .accessibilityLabel("Zur Workout-Ansicht")
            }
        }
        .sheet(isPresented: $showingNewExercise) {
            // Stack HIER, nicht in AddExerciseView (damit Titel/Buttons angezeigt werden)
            NavigationStack {
                AddExerciseView(trainingID: trainingID, afterSave: .dismiss)
                    .environmentObject(store)
            }
        }
        .onChange(of: titleFocused) { focused in
            if !focused && isEditingTitle { commitTitle() }
        }
        // MARK: - Bottom-Button wie im Mockup
        .safeAreaInset(edge: .bottom) {
            HStack {
                Button {
                    router.go(.workoutRun(trainingID: trainingID))
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "play.fill")
                            .imageScale(.large)
                            .foregroundStyle(.blue)
                        Text("Workout starten")
                            .font(.headline)
                            .foregroundStyle(.primary)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color(.systemBackground))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 12)
        }
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
