import SwiftUI

struct WorkoutRunView: View {
    @EnvironmentObject var store: Store
    let trainingID: UUID

    var body: some View {
        List {
            ForEach(training.exercises) { ex in
                Section(ex.name.uppercased()) {
                    ForEach(ex.sets) { set in
                        SetRow(
                            trainingID: trainingID,
                            exerciseID: ex.id,
                            set: set
                        )
                    }
                }
            }
        }
        .navigationTitle(training.title)
    }

    // MARK: - Lookup
    private var training: Training {
        store.trainings.first(where: { $0.id == trainingID }) ?? Training(title: "Training")
    }
}

// MARK: - Einzelner Satz als Checklisten-Zeile
private struct SetRow: View {
    @EnvironmentObject var store: Store
    let trainingID: UUID
    let exerciseID: UUID
    let set: SetEntry

    @State private var tempWeight: Double = 0
    @State private var tempReps: Int = 0

    var body: some View {
        HStack(spacing: 12) {
            // Checkbox
            Button {
                store.toggleSetDone(in: trainingID, exerciseID: exerciseID, setID: set.id)
            } label: {
                Image(systemName: set.isDone ? "checkmark.circle.fill" : "circle")
                    .imageScale(.large)
            }
            .buttonStyle(.plain)

            // Gewicht + Wdh. kompakt editieren
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("\(Int(set.weightKg)) kg")
                        .fontWeight(.semibold)
                    Spacer()
                    Text("\(set.repetition.value) Whd.")
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 16) {
                    Stepper("", value: Binding(
                        get: { Int(tempWeightRounded) },
                        set: { new in store.updateSet(in: trainingID, exerciseID: exerciseID, setID: set.id,
                                                       weight: Double(new)) }
                    ), in: 0...500)
                    .labelsHidden()
                    .frame(width: 120)

                    Stepper("", value: Binding(
                        get: { tempReps },
                        set: { new in store.updateSet(in: trainingID, exerciseID: exerciseID, setID: set.id,
                                                       reps: new) }
                    ), in: 1...50)
                    .labelsHidden()
                    .frame(width: 90)
                }
                .font(.callout)
                .foregroundStyle(.secondary)
            }
        }
        .onAppear {
            tempWeight = set.weightKg
            tempReps = set.repetition.value
        }
        .onChange(of: set.weightKg) { tempWeight = set.weightKg }
        .onChange(of: set.repetition.value) { tempReps = set.repetition.value }
        .opacity(set.isDone ? 0.5 : 1.0)
        .animation(.default, value: set.isDone)
    }

    private var tempWeightRounded: Double {
        // falls du 2.5er Schritte willst -> hier runden
        (set.weightKg * 1).rounded() / 1
    }
}
