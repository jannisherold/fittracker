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
    
    // Neue Übung direkt mit N Sätzen (0/0) anlegen
    func addExercise(to trainingID: UUID, name: String, setCount: Int) {
        guard let tIndex = trainings.firstIndex(where: { $0.id == trainingID }) else { return }
        let sets = (0..<max(0, setCount)).map { _ in
            SetEntry(weightKg: 0, repetition: .init(value: 0), isDone: false)
        }
        trainings[tIndex].exercises.append(Exercise(name: name, sets: sets))
    }

    // Notizen einer Übung setzen
    func updateExerciseNotes(trainingID: UUID, exerciseID: UUID, notes: String) {
        guard let t = trainings.firstIndex(where: { $0.id == trainingID }) else { return }
        guard let e = trainings[t].exercises.firstIndex(where: { $0.id == exerciseID }) else { return }
        trainings[t].exercises[e].notes = notes
    }


    func addSet(to exerciseID: UUID, in trainingID: UUID, weight: Double, reps: Int) {
        guard let t = trainings.firstIndex(where: { $0.id == trainingID }) else { return }
        guard let e = trainings[t].exercises.firstIndex(where: { $0.id == exerciseID }) else { return }
        trainings[t].exercises[e].sets.append(SetEntry(weightKg: weight, repetition: .init(value: reps)))
    }
    
    // Neuen Satz mit Standardwerten hinzufügen
    func addSet(to exerciseID: UUID, in trainingID: UUID) {
        guard let t = trainings.firstIndex(where: { $0.id == trainingID }) else { return }
        guard let e = trainings[t].exercises.firstIndex(where: { $0.id == exerciseID }) else { return }
        let newSet = SetEntry(weightKg: 0, repetition: .init(value: 0), isDone: false)
        trainings[t].exercises[e].sets.append(newSet)
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

    // Satz als erledigt/unerledigt markieren
    func toggleSetDone(in trainingID: UUID, exerciseID: UUID, setID: UUID) {
        guard let t = trainings.firstIndex(where: { $0.id == trainingID }) else { return }
        guard let e = trainings[t].exercises.firstIndex(where: { $0.id == exerciseID }) else { return }
        guard let s = trainings[t].exercises[e].sets.firstIndex(where: { $0.id == setID }) else { return }
        trainings[t].exercises[e].sets[s].isDone.toggle()
    }

    // Gewicht / Wiederholungen eines Satzes ändern
    func updateSet(in trainingID: UUID, exerciseID: UUID, setID: UUID, weight: Double? = nil, reps: Int? = nil) {
        guard let t = trainings.firstIndex(where: { $0.id == trainingID }) else { return }
        guard let e = trainings[t].exercises.firstIndex(where: { $0.id == exerciseID }) else { return }
        guard let s = trainings[t].exercises[e].sets.firstIndex(where: { $0.id == setID }) else { return }
        if let w = weight { trainings[t].exercises[e].sets[s].weightKg = w }
        if let r = reps { trainings[t].exercises[e].sets[s].repetition.value = r }
    }

    
    // Alle Sätze eines Trainings „un-done“ setzen
    func resetSession(trainingID: UUID) {
        guard let t = trainings.firstIndex(where: { $0.id == trainingID }) else { return }
        for e in trainings[t].exercises.indices {
            for s in trainings[t].exercises[e].sets.indices {
                trainings[t].exercises[e].sets[s].isDone = false
            }
        }
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

