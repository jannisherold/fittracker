import SwiftUI

struct ExerciseDetailView: View {
    @EnvironmentObject var store: Store
    let trainingID: UUID
    let exerciseID: UUID

    @State private var weight: Double = 20
    @State private var reps: Int = 8
    @Environment(\.horizontalSizeClass) private var hSize

    var body: some View {
        List {
            if let exercise {
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
                    
                    Button {
                        store.addSet(to: exerciseID, in: trainingID)
                    } label: {
                        Label("Satz hinzufügen", systemImage: "plus")
                    }
                                
                }
            }
        }
        .navigationTitle(exercise?.name ?? "Übung")
        .toolbar { ToolbarItem(placement: .navigationBarTrailing) { EditButton() } }
    }


    // MARK: - Subviews

    private func exerciseSetsList() -> some View {
        List {
            if let exercise {
                Section("SÄTZE") {
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
            } else {
                Text("Übung nicht gefunden").foregroundStyle(.secondary)
            }
        }
    }

    
    private var controlsBar: some View {
        Group {
            if hSize == .compact {         // iPhone hochkant
                VStack(spacing: 12) {
                    weightControl
                    repsControl
                    addButton
                }
            } else {                        // Querformat / iPad
                HStack(spacing: 16) {
                    weightControl
                    repsControl
                    addButton
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }

    private var weightControl: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Gewicht: \(weight, specifier: "%.1f") kg")
                .font(.body)
                .monospacedDigit()
                .lineLimit(1)
            Stepper(value: $weight, in: 0...500, step: 2.5) {
                EmptyView()
            }
            .labelsHidden()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var repsControl: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Wdh.: \(reps)")
                .font(.body)
                .monospacedDigit()
                .lineLimit(1)
            Stepper(value: $reps, in: 1...50) {
                EmptyView()
            }
            .labelsHidden()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var addButton: some View {
        Button {
            store.addSet(to: exerciseID, in: trainingID, weight: weight, reps: reps)
        } label: {
            Label("Hinzufügen", systemImage: "plus.circle.fill")
                .font(.headline)
        }
        .buttonStyle(.borderedProminent)
    }

    // Dein Lookup (exercise) wie gehabt:
    private var exercise: Exercise? {
        guard let t = store.trainings.firstIndex(where: { $0.id == trainingID }) else { return nil }
        return store.trainings[t].exercises.first(where: { $0.id == exerciseID })
    }
}
