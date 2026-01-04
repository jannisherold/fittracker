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

    // MARK: - Rest Timer Settings (local: UserDefaults)

    @Published var restTimerEnabled: Bool = true {
        didSet {
            UserDefaults.standard.set(restTimerEnabled, forKey: "restTimerEnabled")
            print("⏱️ Store: restTimerEnabled -> \(restTimerEnabled)")
        }
    }

    // Total seconds (0...1800)
    @Published var restTimerSeconds: Int = 90 {
        didSet {
            let clamped = max(0, min(restTimerSeconds, 60 * 30)) // 0s ... 30min
            if clamped != restTimerSeconds {
                // ✅ Einmalig korrigieren, dann hört es auf (kein Endlos-Loop)
                restTimerSeconds = clamped
                return
            }

            UserDefaults.standard.set(restTimerSeconds, forKey: "restTimerSeconds")
            print("⏱️ Store: restTimerSeconds -> \(restTimerSeconds)")
        }
    }


    // MARK: - All-time Statistiken

    var totalCompletedWorkouts: Int {
        trainings.reduce(0) { $0 + $1.sessions.count }
    }

    var totalTrainingMinutes: Double {
        let totalSeconds = trainings.flatMap { $0.sessions }.reduce(0.0) { $0 + $1.duration }
        return totalSeconds / 60.0
    }

    var totalMovedWeightKg: Double {
        trainings
            .flatMap { $0.sessions }
            .flatMap { $0.exercises }
            .flatMap { $0.sets }
            .filter { $0.isDone }
            .reduce(0.0) { $0 + ($1.weightKg * Double($1.repetition.value)) }
    }

    var totalRepetitions: Int {
        trainings
            .flatMap { $0.sessions }
            .flatMap { $0.exercises }
            .flatMap { $0.sets }
            .filter { $0.isDone }
            .reduce(0) { $0 + $1.repetition.value }
    }

    // MARK: - Persistence URLs

    private let url: URL = {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent("trainings.json")
    }()

    private let bodyweightURL: URL = {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent("bodyweight.json")
    }()

    init() {
        load()
        loadBodyweight()

        // Load rest timer settings
        if UserDefaults.standard.object(forKey: "restTimerEnabled") != nil {
            restTimerEnabled = UserDefaults.standard.bool(forKey: "restTimerEnabled")
        }
        let secs = UserDefaults.standard.integer(forKey: "restTimerSeconds")
        restTimerSeconds = secs == 0 ? 90 : secs  // default 90 if not set
        restTimerSeconds = max(0, min(restTimerSeconds, 60 * 30))

        print("⏱️ Store init: restTimerEnabled=\(restTimerEnabled), restTimerSeconds=\(restTimerSeconds)")
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

    func beginSession(trainingID: UUID) {
        guard let t = trainings.firstIndex(where: { $0.id == trainingID }) else { return }
        for e in trainings[t].exercises.indices {
            for s in trainings[t].exercises[e].sets.indices {
                trainings[t].exercises[e].sets[s].isDone = false
            }
        }
        trainings[t].currentSessionStart = Date()
    }

    func endSession(trainingID: UUID) {
        guard let t = trainings.firstIndex(where: { $0.id == trainingID }) else { return }
        let exs = trainings[t].exercises

        var map: [UUID: Double] = [:]
        for ex in exs {
            let maxW = ex.sets.map { $0.weightKg }.max() ?? 0
            map[ex.id] = maxW
        }

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

    func addBodyweightEntry(weightKg: Double, date: Date = .now) {
        let entry = BodyweightEntry(date: date, weightKg: weightKg)
        bodyweightEntries.insert(entry, at: 0)
    }

    func resetBodyweightEntries() {
        bodyweightEntries = []
    }

    func deleteAllData() {
        trainings = []
        bodyweightEntries = []
        restTimerEnabled = true
        restTimerSeconds = 90
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
