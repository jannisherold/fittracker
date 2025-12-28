import Foundation


extension KeyedDecodingContainer {
    func decodeFlexibleDate(forKey key: Key) throws -> Date {
        // 1) Standard Date-Decoding (z.B. falls irgendwo schon korrekt)
        if let d = try? decode(Date.self, forKey: key) { return d }

        // 2) ISO8601 String oder String-Timestamp
        if let s = try? decode(String.self, forKey: key) {
            let f = ISO8601DateFormatter()
            if let d = f.date(from: s) { return d }
            if let seconds = Double(s) { return Date(timeIntervalSince1970: seconds) }
        }

        // 3) Numeric timestamp
        if let seconds = try? decode(Double.self, forKey: key) {
            return Date(timeIntervalSince1970: seconds)
        }
        if let secondsInt = try? decode(Int.self, forKey: key) {
            return Date(timeIntervalSince1970: Double(secondsInt))
        }

        throw DecodingError.dataCorruptedError(
            forKey: key,
            in: self,
            debugDescription: "Could not decode Date (expected Date, ISO8601 String, or timestamp)."
        )
    }

    func decodeFlexibleDateIfPresent(forKey key: Key) throws -> Date? {
        guard contains(key) else { return nil }
        // Wenn null drin ist, soll nil rauskommen
        if (try? decodeNil(forKey: key)) == true { return nil }
        return try decodeFlexibleDate(forKey: key)
    }
}


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
    var currentSessionStart: Date? = nil

    enum CodingKeys: String, CodingKey {
        case id, title, date, exercises, sessions, currentSessionStart
    }

    init(
        id: UUID = UUID(),
        title: String,
        date: Date = .now,
        exercises: [Exercise] = [],
        sessions: [WorkoutSession] = [],
        currentSessionStart: Date? = nil
    ) {
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

        // ✅ flexibel: String oder Double
        date = (try? c.decodeFlexibleDate(forKey: .date)) ?? .now

        exercises = try c.decodeIfPresent([Exercise].self, forKey: .exercises) ?? []
        sessions = try c.decodeIfPresent([WorkoutSession].self, forKey: .sessions) ?? []

        // ✅ flexibel + optional
        currentSessionStart = try c.decodeFlexibleDateIfPresent(forKey: .currentSessionStart)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(title, forKey: .title)
        try c.encode(exercises, forKey: .exercises)
        try c.encode(sessions, forKey: .sessions)

        // ✅ Best practice: ISO8601 schreiben
        let f = ISO8601DateFormatter()
        try c.encode(f.string(from: date), forKey: .date)

        if let start = currentSessionStart {
            try c.encode(f.string(from: start), forKey: .currentSessionStart)
        } else {
            try c.encodeNil(forKey: .currentSessionStart)
        }
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

        // ✅ endedAt / startedAt flexibel
        endedAt = (try? c.decodeFlexibleDate(forKey: .endedAt)) ?? .now
        startedAt = (try? c.decodeFlexibleDate(forKey: .startedAt)) ?? endedAt

        maxWeightPerExercise = try c.decodeIfPresent([UUID: Double].self, forKey: .maxWeightPerExercise) ?? [:]
        exercises = try c.decodeIfPresent([SessionExerciseSnapshot].self, forKey: .exercises) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(maxWeightPerExercise, forKey: .maxWeightPerExercise)
        try c.encode(exercises, forKey: .exercises)

        let f = ISO8601DateFormatter()
        try c.encode(f.string(from: startedAt), forKey: .startedAt)
        try c.encode(f.string(from: endedAt), forKey: .endedAt)
    }


    /// ✅ Abgeleitete Dauer der Session
    var duration: TimeInterval {
        endedAt.timeIntervalSince(startedAt)
    }
}

/// ✅ Neues Modell für Körpergewichts-Tracking
struct BodyweightEntry: Identifiable, Codable {
    var id: UUID = UUID()
    var date: Date
    var weightKg: Double

    enum CodingKeys: String, CodingKey {
        case id, date, weightKg
    }

    init(id: UUID = UUID(), date: Date = .now, weightKg: Double) {
        self.id = id
        self.date = date
        self.weightKg = weightKg
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        date = (try? c.decodeFlexibleDate(forKey: .date)) ?? .now
        weightKg = try c.decode(Double.self, forKey: .weightKg)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(weightKg, forKey: .weightKg)

        let f = ISO8601DateFormatter()
        try c.encode(f.string(from: date), forKey: .date)
    }
}

