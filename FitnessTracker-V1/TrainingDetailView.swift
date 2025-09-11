import SwiftUI

struct TrainingDetailView: View {
    @EnvironmentObject var store: Store
    let trainingID: UUID

    @State private var showingNewExercise = false
    @State private var name = ""

    private var trainingIndex: Int? {
        store.trainings.firstIndex(where: { $0.id == trainingID })
    }
    private var training: Training? {
        trainingIndex.flatMap { store.trainings[$0] }
    }

    var body: some View {
        List {
            if let training {
                Section("Übungen") {
                    ForEach(training.exercises) { ex in
                        NavigationLink(ex.name) {
                            ExerciseDetailView(trainingID: trainingID, exerciseID: ex.id)
                        }
                    }
                    .onDelete { offsets in
                                    store.deleteExercise(in: trainingID, at: offsets)
                                }
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) { EditButton() }
                        ToolbarItem(placement: .primaryAction) {
                            Button { showingNewExercise = true } label: { Label("Übung", systemImage: "plus") }
                        }
                    }
                }
            }
        }
        .navigationTitle(training?.title ?? "Training")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showingNewExercise = true } label: {
                    Label("Übung", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingNewExercise) {
            NavigationStack {
                Form { TextField("Übungsname", text: $name) }
                    .navigationTitle("Übung hinzufügen")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) { Button("Abbrechen") { showingNewExercise = false } }
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
