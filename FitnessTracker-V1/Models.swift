import Foundation

struct Repetition: Codable { var value: Int }

struct SetEntry: Identifiable, Codable {
    var id: UUID = UUID()
    var weightKg: Double
    var repetition: Repetition
    var isDone: Bool = false   // ✅ neu

    // Für alte JSONs ohne isDone: Standard = false
    enum CodingKeys: String, CodingKey { case id, weightKg, repetition, isDone }
    init(id: UUID = UUID(), weightKg: Double, repetition: Repetition, isDone: Bool = false) {
        self.id = id; self.weightKg = weightKg; self.repetition = repetition; self.isDone = isDone
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
}
