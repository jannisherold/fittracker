import SwiftUI

struct ExerciseEditView: View {
    @EnvironmentObject var store: Store
    @EnvironmentObject private var router: Router
    @Environment(\.editMode) private var editMode

    let trainingID: UUID
    let exerciseID: UUID

    @State private var isEditingTitle = false
    @State private var draftTitle = ""
    @FocusState private var titleFocused: Bool

    private var exercise: Exercise? {
        guard let t = store.trainings.firstIndex(where: { $0.id == trainingID }) else { return nil }
        return store.trainings[t].exercises.first(where: { $0.id == exerciseID })
    }

    var body: some View {
        ZStack {
            List {
                if let exercise {
                    // MARK: - Übungs-Titel mit Überschrift
                    Section {
                        Group {
                            if isEditingTitle {
                                TextField("Übungsname", text: $draftTitle)
                                    .font(.system(size: 24, weight: .bold))
                                    .textInputAutocapitalization(.words)
                                    .disableAutocorrection(true)
                                    .focused($titleFocused)
                                    .onAppear {
                                        draftTitle = exercise.name
                                        DispatchQueue.main.async { titleFocused = true }
                                    }
                                    .onSubmit { commitTitle() }
                            } else {
                                Text(exercise.name)
                                    .font(.system(size: 24, weight: .bold))
                                    .onTapGesture { isEditingTitle = true }
                            }
                        }
                        .padding(.vertical, 4)
                    } header: {
                        Text("ÜBUNGS-TITEL")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.secondary)
                            .textCase(nil)
                            .padding(.leading, 4)
                    }
                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))

                    // MARK: - Sätze-Liste
                    Section {
                        ForEach(exercise.sets) { set in
                            HStack {
                                Text("\(Int(set.weightKg)) kg")
                                    .fontWeight(.semibold)
                                Spacer()
                                Text("\(set.repetition.value) Wdh.")
                                    .fontWeight(.semibold)
                            }
                        }
                        .onDelete { offsets in
                            store.deleteSet(in: trainingID, exerciseID: exerciseID, at: offsets)
                        }
                    } header: {
                        Text("SÄTZE")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.secondary)
                            .textCase(nil)
                            .padding(.leading, 4)
                    }

                    // MARK: - Satz hinzufügen Button (engerer Abstand)
                    Section {
                        HStack {
                            Spacer()
                            Button {
                                store.addSet(to: exerciseID, in: trainingID)
                            } label: {
                                Label("Satz hinzufügen", systemImage: "plus")
                                    .fontWeight(.semibold)
                            }
                            .labelStyle(.titleAndIcon)
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                            Spacer()
                        }
                        //.padding(.top, 4)
                        .padding(.bottom, 8)
                    }
                    .listRowBackground(Color.clear)

                } else {
                    Text("Übung nicht gefunden").foregroundStyle(.secondary)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: titleFocused) { focused in
                if !focused && isEditingTitle { commitTitle() }
            }
        }
        // Tap außerhalb speichert den Titel
        .background(
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    if isEditingTitle {
                        titleFocused = false
                    }
                }
        )
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)

        // MARK: - Toolbar oben
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    router.replaceTop(with: .workoutEdit(trainingID: trainingID))
                } label: {
                    Image(systemName: "chevron.left")
                }
                .accessibilityLabel("Zur Workout-Bearbeitung")
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
                .accessibilityLabel("Sätze bearbeiten")
            }
        }
    }

    // MARK: - Helper
    private func commitTitle() {
        let new = draftTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !new.isEmpty else {
            isEditingTitle = false
            return
        }
        if let tIdx = store.trainings.firstIndex(where: { $0.id == trainingID }),
           let eIdx = store.trainings[tIdx].exercises.firstIndex(where: { $0.id == exerciseID }) {
            store.trainings[tIdx].exercises[eIdx].name = new
        }
        isEditingTitle = false
    }
}
