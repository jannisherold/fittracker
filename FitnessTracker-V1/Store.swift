import Foundation
import SwiftUI

final class Store: ObservableObject {
    @Published var trainings: [Training] = [] {
        didSet { save() }
    }

    /// ✅ Alle Körpergewichts-Einträge (neueste zuerst)
    @Published var bodyweightEntries: [BodyweightEntry] = [] {
        didSet { saveBodyweight() }
    }
    
    // MARK: - All-time Statistiken

    /// 1) Wie viele Workouts wurden insgesamt absolviert?
    ///    => Anzahl aller gespeicherten Sessions über alle Trainings
    var totalCompletedWorkouts: Int {
        trainings.reduce(0) { partial, training in
            partial + training.sessions.count
        }
    }

    /// 2) Wie viele Minuten wurde insgesamt trainiert?
    ///    => Summe der Dauer aller Sessions (in Minuten)
    var totalTrainingMinutes: Double {
        let totalSeconds = trainings
            .flatMap { $0.sessions }
            .reduce(0.0) { partial, session in
                partial + session.duration
            }
        return totalSeconds / 60.0
    }

    /// 3) Wie viel Gewicht wurde insgesamt bewegt (in kg)?
    ///    Ein Satz mit 100 kg und 10 Wdh. = 1000 kg bewegt.
    ///    Hier werden nur Sätze mit isDone == true gezählt.
    var totalMovedWeightKg: Double {
        trainings
            .flatMap { $0.sessions }
            .flatMap { $0.exercises }
            .flatMap { $0.sets }
            .filter { $0.isDone }
            .reduce(0.0) { partial, set in
                partial + set.weightKg * Double(set.repetition.value)
            }
    }

    /// 4) Gesamtzahl aller Wiederholungen (nur erledigte Sets)
    var totalRepetitions: Int {
        trainings
            .flatMap { $0.sessions }
            .flatMap { $0.exercises }
            .flatMap { $0.sets }
            .filter { $0.isDone }
            .reduce(0) { partial, set in
                partial + set.repetition.value
            }
    }


    // Bestehende Trainings-Datei
    private let url: URL = {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent("trainings.json")
    }()

    // ✅ Neue Datei nur für Körpergewicht
    private let bodyweightURL: URL = {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent("bodyweight.json")
    }()

    init() {
        load()
        loadBodyweight()
    }

    // MARK: - Mutations Trainings
    func addTraining(title: String) {
        trainings.insert(Training(title: title), at: 0)
    }
    
    func moveTraining(from source: IndexSet, to destination: Int) {
        trainings.move(fromOffsets: source, toOffset: destination)
    }

    func deleteTraining(at offsets: IndexSet) {
        trainings.remove(atOffsets: offsets)
    }

    func addExercise(to trainingID: UUID, name: String) {
        guard let t = trainings.firstIndex(where: { $0.id == trainingID }) else { return }
        trainings[t].exercises.append(Exercise(name: name))
    }

    func addExercise(to trainingID: UUID, name: String, setCount: Int) {
        guard let tIndex = trainings.firstIndex(where: { $0.id == trainingID }) else { return }
        let sets = (0..<max(0, setCount)).map { _ in
            SetEntry(weightKg: 0, repetition: .init(value: 0), isDone: false)
        }
        trainings[tIndex].exercises.append(Exercise(name: name, sets: sets))
    }

    func updateExerciseNotes(trainingID: UUID, exerciseID: UUID, notes: String) {
        guard let t = trainings.firstIndex(where: { $0.id == trainingID }) else { return }
        guard let e = trainings[t].exercises.firstIndex(where: { $0.id == exerciseID }) else { return }
        trainings[t].exercises[e].notes = notes
    }

    func moveExercise(in trainingID: UUID, from source: IndexSet, to destination: Int) {
        guard let t = trainings.firstIndex(where: { $0.id == trainingID }) else { return }
        trainings[t].exercises.move(fromOffsets: source, toOffset: destination)
    }

    func addSet(to exerciseID: UUID, in trainingID: UUID, weight: Double, reps: Int) {
        guard let t = trainings.firstIndex(where: { $0.id == trainingID }) else { return }
        guard let e = trainings[t].exercises.firstIndex(where: { $0.id == exerciseID }) else { return }
        trainings[t].exercises[e].sets.append(SetEntry(weightKg: weight, repetition: .init(value: reps)))
    }

    func addSet(to exerciseID: UUID, in trainingID: UUID) {
        guard let t = trainings.firstIndex(where: { $0.id == trainingID }) else { return }
        guard let e = trainings[t].exercises.firstIndex(where: { $0.id == exerciseID }) else { return }
        let newSet = SetEntry(weightKg: 0, repetition: .init(value: 0), isDone: false)
        trainings[t].exercises[e].sets.append(newSet)
    }

    func deleteExercise(in trainingID: UUID, at offsets: IndexSet) {
        guard let t = trainings.firstIndex(where: { $0.id == trainingID }) else { return }
        trainings[t].exercises.remove(atOffsets: offsets)
    }

    func deleteSet(in trainingID: UUID, exerciseID: UUID, at offsets: IndexSet) {
        guard let t = trainings.firstIndex(where: { $0.id == trainingID }) else { return }
        guard let e = trainings[t].exercises.firstIndex(where: { $0.id == exerciseID }) else { return }
        trainings[t].exercises[e].sets.remove(atOffsets: offsets)
    }

    func toggleSetDone(in trainingID: UUID, exerciseID: UUID, setID: UUID) {
        guard let t = trainings.firstIndex(where: { $0.id == trainingID }) else { return }
        guard let e = trainings[t].exercises.firstIndex(where: { $0.id == exerciseID }) else { return }
        guard let s = trainings[t].exercises[e].sets.firstIndex(where: { $0.id == setID }) else { return }
        trainings[t].exercises[e].sets[s].isDone.toggle()
    }

    func updateSet(in trainingID: UUID, exerciseID: UUID, setID: UUID, weight: Double? = nil, reps: Int? = nil) {
        guard let t = trainings.firstIndex(where: { $0.id == trainingID }) else { return }
        guard let e = trainings[t].exercises.firstIndex(where: { $0.id == exerciseID }) else { return }
        guard let s = trainings[t].exercises[e].sets.firstIndex(where: { $0.id == setID }) else { return }
        if let w = weight { trainings[t].exercises[e].sets[s].weightKg = w }
        if let r = reps { trainings[t].exercises[e].sets[s].repetition.value = r }
    }

    func resetSession(trainingID: UUID) {
        guard let t = trainings.firstIndex(where: { $0.id == trainingID }) else { return }
        for e in trainings[t].exercises.indices {
            for s in trainings[t].exercises[e].sets.indices {
                trainings[t].exercises[e].sets[s].isDone = false
            }
        }
        trainings[t].currentSessionStart = nil
    }

    // ✅ Sessionstart: alle Sätze auf „nicht erledigt“ + Startzeit setzen
    func beginSession(trainingID: UUID) {
        guard let t = trainings.firstIndex(where: { $0.id == trainingID }) else { return }
        for e in trainings[t].exercises.indices {
            for s in trainings[t].exercises[e].sets.indices {
                trainings[t].exercises[e].sets[s].isDone = false
            }
        }
        trainings[t].currentSessionStart = Date()
    }

    // ✅ Session beenden:
    // - Max-Gewichte berechnen (wie bisher)
    // - Vollständigen Snapshot aller Übungen & Sätze speichern
    // - Session (mit startedAt/endedAt) sichern, Start löschen
    func endSession(trainingID: UUID) {
        guard let t = trainings.firstIndex(where: { $0.id == trainingID }) else { return }
        let exs = trainings[t].exercises

        // Bisherige Logik: Max-Gewicht pro Übung
        var map: [UUID: Double] = [:]
        for ex in exs {
            let maxW = ex.sets.map { $0.weightKg }.max() ?? 0
            map[ex.id] = maxW
        }

        // ✅ Neue Logik: kompletter Snapshot aller Übungen & Sets
        let exerciseSnapshots: [SessionExerciseSnapshot] = exs.map { ex in
            let setSnapshots: [SessionSetSnapshot] = ex.sets.map { set in
                SessionSetSnapshot(
                    originalSetID: set.id,
                    weightKg: set.weightKg,
                    repetition: set.repetition,
                    isDone: set.isDone
                )
            }

            return SessionExerciseSnapshot(
                originalExerciseID: ex.id,
                name: ex.name,
                sets: setSnapshots,
                notes: ex.notes
            )
        }

        let ended = Date()
        let started = trainings[t].currentSessionStart ?? ended

        let session = WorkoutSession(
            startedAt: started,
            endedAt: ended,
            maxWeightPerExercise: map,
            exercises: exerciseSnapshots
        )

        trainings[t].sessions.insert(session, at: 0)
        trainings[t].currentSessionStart = nil
    }

    // MARK: - Mutations Körpergewicht

    /// ✅ Neuen Körpergewichts-Eintrag hinzufügen (neueste Einträge vorne)
    func addBodyweightEntry(weightKg: Double, date: Date = .now) {
        let entry = BodyweightEntry(date: date, weightKg: weightKg)
        bodyweightEntries.insert(entry, at: 0)
    }

    /// ✅ Alle Körpergewichts-Daten löschen
    func resetBodyweightEntries() {
        bodyweightEntries = []
    }

    /// ✅ Alle App-Daten (Trainings + Körpergewicht) löschen
    func deleteAllData() {
        trainings = []
        bodyweightEntries = []
    }

    // MARK: - Persistence Trainings
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
            trainings = []
        }
    }

    // MARK: - Persistence Körpergewicht
    private func saveBodyweight() {
        do {
            let data = try JSONEncoder().encode(bodyweightEntries)
            try data.write(to: bodyweightURL, options: [.atomic])
        } catch {
            print("Save bodyweight error:", error)
        }
    }

    private func loadBodyweight() {
        do {
            let data = try Data(contentsOf: bodyweightURL)
            bodyweightEntries = try JSONDecoder().decode([BodyweightEntry].self, from: data)
        } catch {
            bodyweightEntries = []
        }
    }
}
