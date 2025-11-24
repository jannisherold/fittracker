import Foundation

struct Repetition: Codable {
    var value: Int
}

struct SetEntry: Identifiable, Codable {
    var id: UUID = UUID()
    var weightKg: Double
    var repetition: Repetition
    var isDone: Bool = false   // ✅ neu

    enum CodingKeys: String, CodingKey {
        case id, weightKg, repetition, isDone
    }

    init(id: UUID = UUID(), weightKg: Double, repetition: Repetition, isDone: Bool = false) {
        self.id = id
        self.weightKg = weightKg
        self.repetition = repetition
        self.isDone = isDone
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        weightKg = try c.decode(Double.self, forKey: .weightKg)
        repetition = try c.decode(Repetition.self, forKey: .repetition)
        isDone = try c.decodeIfPresent(Bool.self, forKey: .isDone) ?? false
    }
}

struct Exercise: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var sets: [SetEntry] = []
    var notes: String = ""
}

struct Training: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var date: Date = .now
    var exercises: [Exercise] = []
    var sessions: [WorkoutSession] = []
    /// ✅ Laufende Session (nil wenn keine läuft). Wird beim Start gesetzt und beim Beenden geleert.
    var currentSessionStart: Date? = nil

    enum CodingKeys: String, CodingKey {
        case id, title, date, exercises, sessions, currentSessionStart
    }

    init(id: UUID = UUID(), title: String, date: Date = .now, exercises: [Exercise] = [], sessions: [WorkoutSession] = [], currentSessionStart: Date? = nil) {
        self.id = id
        self.title = title
        self.date = date
        self.exercises = exercises
        self.sessions = sessions
        self.currentSessionStart = currentSessionStart
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        title = try c.decode(String.self, forKey: .title)
        date = try c.decodeIfPresent(Date.self, forKey: .date) ?? .now
        exercises = try c.decodeIfPresent([Exercise].self, forKey: .exercises) ?? []
        sessions = try c.decodeIfPresent([WorkoutSession].self, forKey: .sessions) ?? []
        currentSessionStart = try c.decodeIfPresent(Date.self, forKey: .currentSessionStart)
    }
}

//
// ✅ Neue Snapshot-Modelle für komplette Session-Daten
//

struct SessionSetSnapshot: Identifiable, Codable {
    var id: UUID = UUID()
    /// Referenz auf das ursprüngliche Set (optional für spätere Auswertungen)
    var originalSetID: UUID
    var weightKg: Double
    var repetition: Repetition
    var isDone: Bool

    enum CodingKeys: String, CodingKey {
        case id, originalSetID, weightKg, repetition, isDone
    }

    init(id: UUID = UUID(), originalSetID: UUID, weightKg: Double, repetition: Repetition, isDone: Bool) {
        self.id = id
        self.originalSetID = originalSetID
        self.weightKg = weightKg
        self.repetition = repetition
        self.isDone = isDone
    }
}

struct SessionExerciseSnapshot: Identifiable, Codable {
    var id: UUID = UUID()
    /// Referenz auf die ursprüngliche Übung
    var originalExerciseID: UUID
    var name: String
    var sets: [SessionSetSnapshot]
    var notes: String

    enum CodingKeys: String, CodingKey {
        case id, originalExerciseID, name, sets, notes
    }

    init(id: UUID = UUID(), originalExerciseID: UUID, name: String, sets: [SessionSetSnapshot], notes: String) {
        self.id = id
        self.originalExerciseID = originalExerciseID
        self.name = name
        self.sets = sets
        self.notes = notes
    }
}

/// Session-Modell: speichert Start- und Endzeit + je Übung das Maximalgewicht innerhalb dieser Session
/// ✅ Zusätzlich: kompletter Snapshot aller Übungen & Sets für diese Session
struct WorkoutSession: Identifiable, Codable {
    var id: UUID = UUID()
    var startedAt: Date
    var endedAt: Date
    // Mapping: Exercise.ID -> Maximalgewicht
    var maxWeightPerExercise: [UUID: Double]
    // ✅ Vollständige Daten der Session
    var exercises: [SessionExerciseSnapshot]

    enum CodingKeys: String, CodingKey {
        case id, startedAt, endedAt, maxWeightPerExercise, exercises
    }

    init(
        id: UUID = UUID(),
        startedAt: Date,
        endedAt: Date,
        maxWeightPerExercise: [UUID: Double],
        exercises: [SessionExerciseSnapshot] = []
    ) {
        self.id = id
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.maxWeightPerExercise = maxWeightPerExercise
        self.exercises = exercises
    }

    // Rückwärtskompatibel: Falls alte JSONs nur endedAt hatten, setze startedAt = endedAt
    // und exercises = []
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        endedAt = try c.decodeIfPresent(Date.self, forKey: .endedAt) ?? .now
        startedAt = try c.decodeIfPresent(Date.self, forKey: .startedAt) ?? endedAt
        maxWeightPerExercise = try c.decodeIfPresent([UUID: Double].self, forKey: .maxWeightPerExercise) ?? [:]
        exercises = try c.decodeIfPresent([SessionExerciseSnapshot].self, forKey: .exercises) ?? []
    }

    /// ✅ Abgeleitete Dauer der Session
    var duration: TimeInterval {
        endedAt.timeIntervalSince(startedAt)
    }
}
