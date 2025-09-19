import SwiftUI

struct ExerciseEditView: View {
    @EnvironmentObject var store: Store
    @EnvironmentObject private var router: Router

    let trainingID: UUID
    let exerciseID: UUID

    // Titel-Editing analog WorkoutEditView
    @State private var isEditingTitle = false
    @State private var draftTitle = ""
    @FocusState private var titleFocused: Bool

    // Nur für Delete-Edit (kein Reorder)
    @Environment(\.editMode) private var editMode

    var body: some View {
        ZStack {
            List {
                if let exercise {
                    // -- Editierbarer Titel-Kasten (analog Workout) --
                    Section {
                        Group {
                            if isEditingTitle {
                                TextField("Übungsname", text: $draftTitle)
                                    .font(.system(size: 34, weight: .bold))
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
                                    .font(.system(size: 34, weight: .bold))
                                    .onTapGesture { isEditingTitle = true }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    // wirkt wie ein großer Titel
                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                    // -- Ende Titel --

                    // -- Sätze-Liste mit Header & Stift (ohne Verschieben) --
                    Section {
                        ForEach(exercise.sets) { set in
                            HStack {
                                Text("\(Int(set.weightKg)) kg")
                                Spacer()
                                Text("\(set.repetition.value) Whd.")
                            }
                        }
                        .onDelete { offsets in
                            store.deleteSet(in: trainingID, exerciseID: exerciseID, at: offsets)
                        }
                    } header: {
                        HStack {
                            Text("SÄTZE")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.secondary)

                            Spacer()
                            Button {
                                withAnimation {
                                    // nur Delete-Modus toggeln (kein .onMove)
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
                            .accessibilityLabel("Sätze bearbeiten")
                            .contentShape(Rectangle())
                            .padding(.vertical, 8)
                        }
                        .textCase(nil)
                        .padding(.horizontal, 0)
                        .padding(.leading, 4)
                        .padding(.trailing, 4)
                    }
                    // -- Ende Sätze-Liste --

                    // -- Großer, prominenter Button: „Satz hinzufügen“ --
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
                        .padding(.vertical, 8)
                    }
                    .listRowBackground(Color.clear)
                } else {
                    Text("Übung nicht gefunden").foregroundStyle(.secondary)
                }
            }
            .navigationTitle("") // eigener großer Titel oben in der Liste
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: titleFocused) { focused in
                if !focused && isEditingTitle { commitTitle() }
            }
        }
        // Tap außerhalb speichert den Titel (wie bei WorkoutEditView)
        .background(
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    if isEditingTitle {
                        titleFocused = false // löst commitTitle() über onChange aus
                    }
                }
        )
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    // immer zurück zur WorkoutEditView für dasselbe Training
                    router.replaceTop(with: .workoutEdit(trainingID: trainingID))
                } label: {
                    Image(systemName: "chevron.left")
                }
                .accessibilityLabel("Zur Workout-Bearbeitung")
            }
        }
    }

    // MARK: - Helpers

    private func commitTitle() {
        let new = draftTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !new.isEmpty else {
            isEditingTitle = false
            return
        }
        // Übungsnamen im Store aktualisieren
        if let tIdx = store.trainings.firstIndex(where: { $0.id == trainingID }),
           let eIdx = store.trainings[tIdx].exercises.firstIndex(where: { $0.id == exerciseID }) {
            store.trainings[tIdx].exercises[eIdx].name = new
        }
        isEditingTitle = false
    }

    private var exercise: Exercise? {
        guard let t = store.trainings.firstIndex(where: { $0.id == trainingID }) else { return nil }
        return store.trainings[t].exercises.first(where: { $0.id == exerciseID })
    }
}
