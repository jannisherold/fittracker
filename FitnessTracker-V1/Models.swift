//
//  Models.swift
//  FitnessTracker-V1
//
//  Created by Jannis Herold on 28.08.25.
//
import SwiftUI

// Schritt 1: Projektgerüst + Domain-Modelle
// -------------------------------------------------
// ➡️ Anleitung: Erstelle in Xcode eine neue Datei (File > New > File > Swift File)
// Name: Models.swift
// Füge diesen Code dort ein.
//
// Diese Models brauchst du für die App-Logik.
// ContentView.swift bleibt für die UI.

struct Repetition {
    var value: Int
}

struct SetEntry: Identifiable {
    let id: UUID = UUID()
    var weightKg: Double
    var repetition: Repetition
}

struct Exercise: Identifiable {
    let id: UUID = UUID()
    var name: String
    var sets: [SetEntry] = []
}

struct Training: Identifiable {
    let id: UUID = UUID()
    var title: String
    var date: Date = .now
    var exercises: [Exercise] = []
}



