import SwiftUI

struct TrainingDetailView: View {
    @EnvironmentObject var store: Store
    let trainingID: UUID

    @State private var showingNewExercise = false
    @State private var name = ""

    private var training: Training? {
        store.trainings.first(where: { $0.id == trainingID })
    }

    var body: some View {
        // ⬇️ ÄUSSERSTE View
        List {
            if let training {
                Section("ÜBUNGEN") {
                    ForEach(training.exercises) { ex in
                        NavigationLink(ex.name) {
                            ExerciseDetailView(trainingID: trainingID, exerciseID: ex.id)
                        }
                    }
                    .onDelete { offsets in
                        store.deleteExercise(in: trainingID, at: offsets)
                    }
                }
            }
        }
        .navigationTitle(training?.title ?? "Training")
        // ⬇️ Toolbar EINMALIG an den Screen hängen (nicht in List / Section)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                EditButton()
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button { showingNewExercise = true } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Übung hinzufügen")
            }
        }
        .sheet(isPresented: $showingNewExercise) {
            NavigationStack {
                Form { TextField("Übungsname", text: $name) }
                    .navigationTitle("Übung hinzufügen")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Abbrechen") { showingNewExercise = false }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Speichern") {
                                let n = name.trimmingCharacters(in: .whitespacesAndNewlines)
                                guard !n.isEmpty else { return }
                                store.addExercise(to: trainingID, name: n)
                                name = ""
                                showingNewExercise = false
                            }
                        }
                    }
            }
            .presentationDetents([.height(220)])
        }
    }
}
