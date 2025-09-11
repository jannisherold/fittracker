import Foundation

struct Repetition: Codable {
    var value: Int
}

struct SetEntry: Identifiable, Codable {
    var id: UUID = UUID()          // <- var statt let
    var weightKg: Double
    var repetition: Repetition
}

struct Exercise: Identifiable, Codable {
    var id: UUID = UUID()          // <- var statt let
    var name: String
    var sets: [SetEntry] = []
}

struct Training: Identifiable, Codable {
    var id: UUID = UUID()          // <- var statt let
    var title: String
    var date: Date = .now
    var exercises: [Exercise] = []
}
