import SwiftUI

struct ExerciseDetailView: View {
    @EnvironmentObject var store: Store
    let trainingID: UUID
    let exerciseID: UUID

    @State private var weight: Double = 20
    @State private var reps: Int = 8

    // MARK: - Lookups
    private var trainingIndex: Int? {
        store.trainings.firstIndex(where: { $0.id == trainingID })
    }
    private var exerciseIndex: Int? {
        guard let t = trainingIndex else { return nil }
        return store.trainings[t].exercises.firstIndex(where: { $0.id == exerciseID })
    }
    private var exercise: Exercise? {
        guard let t = trainingIndex, let e = exerciseIndex else { return nil }
        return store.trainings[t].exercises[e]
    }

    var body: some View {
        Group {
            if let exercise {
                VStack {
                    exerciseSetsList(exercise)     // ausgelagert -> weniger Komplexität für den Compiler
                    Divider()
                    addSetBar                       // ebenfalls ausgelagert
                }
                .navigationTitle(exercise.name)
                .toolbar { ToolbarItem(placement: .navigationBarTrailing) { EditButton() } }
            } else {
                Text("Übung nicht gefunden")
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private func exerciseSetsList(_ exercise: Exercise) -> some View {
        List {
            Section("Sätze") {
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
            }
        }
    }

    private var addSetBar: some View {
        HStack(spacing: 16) {
            Stepper(value: $weight, in: 0...500, step: 2.5) {
                Text("Gewicht: \(weight, specifier: "%.1f") kg")
            }
            Stepper(value: $reps, in: 1...50) {
                Text("Wdh.: \(reps)")
            }
            Button {
                store.addSet(to: exerciseID, in: trainingID, weight: weight, reps: reps)
            } label: {
                Label("Hinzufügen", systemImage: "plus.circle.fill")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
