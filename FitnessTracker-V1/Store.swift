import Foundation
import SwiftUI

final class Store: ObservableObject {
    @Published var trainings: [Training] = [] { didSet { save() } }

    private let url: URL = {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent("trainings.json")
    }()

    init() { load() }

    // MARK: - Mutations
    func addTraining(title: String) {
        trainings.insert(Training(title: title), at: 0)
    }

    func addExercise(to trainingID: UUID, name: String) {
        guard let t = trainings.firstIndex(where: { $0.id == trainingID }) else { return }
        trainings[t].exercises.append(Exercise(name: name))
    }

    func addSet(to exerciseID: UUID, in trainingID: UUID, weight: Double, reps: Int) {
        guard let t = trainings.firstIndex(where: { $0.id == trainingID }) else { return }
        guard let e = trainings[t].exercises.firstIndex(where: { $0.id == exerciseID }) else { return }
        trainings[t].exercises[e].sets.append(SetEntry(weightKg: weight, repetition: .init(value: reps)))
    }

    // Trainings löschen (aus Listen .onDelete)
    func deleteTraining(at offsets: IndexSet) {
        trainings.remove(atOffsets: offsets)
    }

    // Übungen löschen (innerhalb eines Trainings)
    func deleteExercise(in trainingID: UUID, at offsets: IndexSet) {
        guard let t = trainings.firstIndex(where: { $0.id == trainingID }) else { return }
        trainings[t].exercises.remove(atOffsets: offsets)
    }

    // Sätze löschen (innerhalb einer Übung)
    func deleteSet(in trainingID: UUID, exerciseID: UUID, at offsets: IndexSet) {
        guard let t = trainings.firstIndex(where: { $0.id == trainingID }) else { return }
        guard let e = trainings[t].exercises.firstIndex(where: { $0.id == exerciseID }) else { return }
        trainings[t].exercises[e].sets.remove(atOffsets: offsets)
    }

    
    // MARK: - Persistence
    private func save() {
        do {
            let data = try JSONEncoder().encode(trainings)
            try data.write(to: url, options: [.atomic])
        } catch {
            print("Save error:", error)
        }
    }

    private func load() {
        do {
            let data = try Data(contentsOf: url)
            trainings = try JSONDecoder().decode([Training].self, from: data)
        } catch {
            trainings = [] // Erststart oder Datei fehlt -> ok
        }
    }
}

