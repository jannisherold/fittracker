import SwiftUI

// Später kommt hier unser Store rein; vorerst halten wir es im View State.
struct ContentView: View {
    @State private var trainings: [Training] = []
    @State private var showingNew = false
    @State private var newTitle = ""

    var body: some View {
        NavigationStack {
            List {
                ForEach(trainings) { t in
                    NavigationLink(t.title) {
                        TrainingDetailView(training: binding(for: t))
                    }
                }
            }
            .navigationTitle("Trainings")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingNew = true
                    } label: {
                        Label("Neues Training", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNew) {
                NavigationStack {
                    Form {
                        TextField("Titel (z. B. Push, Pull, Beine)", text: $newTitle)
                    }
                    .navigationTitle("Training anlegen")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Abbrechen") { showingNew = false }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Speichern") {
                                guard !newTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                                trainings.insert(Training(title: newTitle), at: 0)
                                newTitle = ""
                                showingNew = false
                            }
                            .disabled(newTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                }
                .presentationDetents([.height(220)])
            }
        }
    }

    // Hilfsfunktion: Binding für ein Training finden
    private func binding(for training: Training) -> Binding<Training> {
        guard let index = trainings.firstIndex(where: { $0.id == training.id }) else {
            fatalError("Training not found")
        }
        return $trainings[index]
    }
}

struct TrainingDetailView: View {
    @Binding var training: Training

    var body: some View {
        List {
            Section("Übungen") {
                ForEach(training.exercises) { ex in
                    NavigationLink(ex.name) {
                        ExerciseDetailView(training: $training, exercise: binding(for: ex))
                    }
                }
            }
        }
        .navigationTitle(training.title)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink {
                    NewExerciseView(training: $training)
                } label: {
                    Label("Übung", systemImage: "plus")
                }
            }
        }
    }

    private func binding(for exercise: Exercise) -> Binding<Exercise> {
        guard let index = training.exercises.firstIndex(where: { $0.id == exercise.id }) else {
            fatalError("Exercise not found")
        }
        return $training.exercises[index]
    }
}

struct NewExerciseView: View {
    @Binding var training: Training
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""

    var body: some View {
        Form { TextField("Übungsname", text: $name) }
            .navigationTitle("Übung hinzufügen")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Abbrechen") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                        training.exercises.append(Exercise(name: name))
                        dismiss()
                    }
                }
            }
    }
}

struct ExerciseDetailView: View {
    @Binding var training: Training
    @Binding var exercise: Exercise

    @State private var weight: Double = 20
    @State private var reps: Int = 8

    var body: some View {
        VStack {
            List {
                Section("Sätze") {
                    ForEach(exercise.sets) { set in
                        HStack {
                            Text("\(Int(set.weightKg)) kg")
                            Spacer()
                            Text("\(set.repetition.value) Whd.")
                        }
                    }
                }
            }
            Divider()
            HStack(spacing: 16) {
                Stepper(value: $weight, in: 0...500, step: 2.5) {
                    Text("Gewicht: \(weight, specifier: "%.1f") kg")
                }
                Stepper(value: $reps, in: 1...50) {
                    Text("Wdh.: \(reps)")
                }
                Button {
                    exercise.sets.append(SetEntry(weightKg: weight, repetition: .init(value: reps)))
                } label: {
                    Label("Hinzufügen", systemImage: "plus.circle.fill")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .navigationTitle(exercise.name)
    }
}
