import SwiftUI
import Charts
import UIKit

/// Zeigt pro Übung eines Workouts einen kleinen Verlauf (X = Sessions, Y = Gewicht).
struct ProgressDetailView: View {
    @EnvironmentObject var store: Store

    let trainingID: UUID

    // Neu: Ausgewählte Übung + Punkt für das Crosshair
    @State private var selectedExerciseID: UUID?          // welche Übung gerade "aktiv" ist
    @State private var selectedPoint: ExercisePoint?      // welcher Datenpunkt dort ausgewählt ist
    @State private var impactFeedback = UIImpactFeedbackGenerator(style: .rigid)
    
    var body: some View {
        List {
            if training.exercises.isEmpty {
                Section {
                    Text("Dieses Workout hat noch keine Übungen")
                        .foregroundStyle(.secondary)
                }
            } else {
                ForEach(training.exercises) { ex in
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(ex.name)
                                .font(.headline)

                            let data = points(for: ex.id) // Neu: einmal berechnet, mehrfach genutzt

                            if data.isEmpty {
                                Text("Noch keine Daten aus Sessions")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            } else {
                                Chart {
                                    // Bisherige Linie + Punkte
                                    ForEach(data) { p in
                                        LineMark(
                                            x: .value("Session", p.index),
                                            y: .value("Gewicht (kg)", p.weight)
                                        )
                                        .interpolationMethod(.linear)
                                        .foregroundStyle(.blue)
                                        /*
                                        PointMark(
                                            x: .value("Session", p.index),
                                            y: .value("Gewicht (kg)", p.weight)
                                        )
                                        .foregroundStyle(.blue)
                                         */
                                    }

                                    // Neu: Crosshair + hervorgehobener Punkt
                                    if selectedExerciseID == ex.id, let sp = selectedPoint {
                                        RuleMark(
                                            x: .value("Session", sp.index)
                                        )
                                        .foregroundStyle(.gray)
                                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))

                                        PointMark(
                                            x: .value("Session", sp.index),
                                            y: .value("Gewicht (kg)", sp.weight)
                                        )
                                        .symbolSize(80) // etwas größer als die normalen Punkte
                                    }
                                }
                                .chartXAxis(.hidden)
                                .chartYAxis {
                                    AxisMarks() { value in
                                        AxisGridLine()
                                        AxisTick()
                                        AxisValueLabel()
                                    }
                                }
                                .chartXScale(domain: (data.first?.index ?? 0)...(data.last?.index ?? 0))
                                .frame(height: 160)
                                .padding(.top, 4)
                                // Neu: Chart interaktiv machen (Drag → Crosshair)
                                .chartOverlay { proxy in
                                    GeometryReader { geo in
                                        Rectangle()
                                            .fill(.clear) // unsichtbares Overlay
                                            .contentShape(Rectangle()) // macht die ganze Fläche tappbar
                                            .gesture(
                                                DragGesture()
                                                    .onChanged { value in
                                                        // Plot-Area im Parent-Coordinate-Space
                                                        let frame = geo[proxy.plotAreaFrame]

                                                        // Nur reagieren, wenn Finger innerhalb der Plot-Area ist
                                                        guard frame.contains(value.location) else { return }

                                                        // X-Wert (Session-Index) aus der Fingerposition lesen
                                                        if let sessionIndex: Int = proxy.value(atX: value.location.x, as: Int.self) {
                                                            // Nächstgelegenen Datenpunkt finden
                                                            if let nearest = data.min(by: { abs($0.index - sessionIndex) < abs($1.index - sessionIndex) }) {

                                                                // ⬇️ NEU: Nur wenn wir auf einen anderen Punkt springen → Haptik
                                                                if nearest.index != selectedPoint?.index {
                                                                    impactFeedback.impactOccurred()
                                                                }

                                                                selectedExerciseID = ex.id
                                                                selectedPoint = nearest
                                                            }
                                                        }
                                                    }
                                                    .onEnded { _ in
                                                        // Verhalten wie Aktien-App: Crosshair wieder ausblenden
                                                        selectedExerciseID = nil
                                                        selectedPoint = nil
                                                    }
                                            )
                                    }
                                }

                                // Kleiner Meta-Block unten
                                if let sp = (selectedExerciseID == ex.id ? selectedPoint : nil) {
                                    // Neu: wenn ein Punkt ausgewählt ist, dessen Infos anzeigen
                                    Text("Gewicht: \(formatKg(sp.weight)) kg - \(sp.date.formatted(date: .abbreviated, time: .omitted))")
                                        .font(.footnote)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.primary)
                                } else if let last = lastPoint(for: ex.id) {
                                    // Fallback: wie bisher "Aktuell"
                                    Text("Aktuell: \(formatKg(last.weight)) kg - \(last.date.formatted(date: .abbreviated, time: .omitted))")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
        }
        .navigationTitle(training.title)
    }

    // MARK: - Datenmodell für die Charts
    private struct ExercisePoint: Identifiable, Equatable { // Neu: Equatable für Vergleiche
        let id = UUID()
        let index: Int     // 1...N (chronologisch)
        let date: Date
        let weight: Double
    }

    private var training: Training {
        store.trainings.first(where: { $0.id == trainingID }) ?? Training(title: "Training")
    }

    /// Liefert die Punkte für eine Übung chronologisch (älteste Session links, neueste rechts).
    private func points(for exerciseID: UUID) -> [ExercisePoint] {
        // Sessions in Store werden als neueste zuerst eingefügt -> für Chronologie umdrehen.
        let chronological = training.sessions.reversed()

        // Wir nehmen nur Sessions, in denen die Übung ein Max-Gewicht hat (> 0).
        let values: [(Int, Date, Double)] = chronological.enumerated().compactMap { (idx, session) in
            if let w = session.maxWeightPerExercise[exerciseID], w > 0 {
                return (idx + 1, session.endedAt, w)
            } else {
                return nil
            }
        }

        return values.map { ExercisePoint(index: $0.0, date: $0.1, weight: $0.2) }
    }

    private func lastPoint(for exerciseID: UUID) -> ExercisePoint? {
        points(for: exerciseID).last
    }

    private func formatKg(_ value: Double) -> String {
        // Gleiche Logik wie in deiner Run-View: ohne „unnötige“ Nullen
        let frac = value - floor(value)
        if abs(frac) < 0.0001 { return "\(Int(value))" }
        // Unterstütze 0.125er Schritte
        let stepped = (round(value * 8) / 8.0)
        let intPart = Int(floor(stepped))
        let fracPart = stepped - Double(intPart)
        let label: String
        switch fracPart {
        case 0.125: label = "125"
        case 0.250: label = "25"
        case 0.375: label = "375"
        case 0.500: label = "5"
        case 0.625: label = "625"
        case 0.750: label = "75"
        case 0.875: label = "875"
        default:
            // Fallback mit eine Dezimalstelle
            return String(format: "%.1f", value)
        }
        return "\(intPart),\(label)"
    }
}

// MARK: - Preview

struct ProgressDetailView_Previews: PreviewProvider {

    static var sampleTraining: Training {
        // Beispiel-Exercises
        let bench = Exercise(name: "Bankdrücken", sets: [
            SetEntry(weightKg: 60, repetition: .init(value: 8)),
            SetEntry(weightKg: 65, repetition: .init(value: 6)),
            SetEntry(weightKg: 70, repetition: .init(value: 4))
        ])

        let squat = Exercise(name: "Kniebeuge", sets: [
            SetEntry(weightKg: 80, repetition: .init(value: 8)),
            SetEntry(weightKg: 90, repetition: .init(value: 5))
        ])

        let deadlift = Exercise(name: "Kreuzheben", sets: [
            SetEntry(weightKg: 100, repetition: .init(value: 5)),
            SetEntry(weightKg: 110, repetition: .init(value: 3))
        ])

        let exercises = [bench, squat, deadlift]

        let now = Date()
        let day: TimeInterval = 24 * 60 * 60

        // Beispiel-Sessions für Chart-Daten
        let session1 = WorkoutSession(
            startedAt: now.addingTimeInterval(-14 * day),
            endedAt: now.addingTimeInterval(-14 * day + 3000),
            maxWeightPerExercise: [
                bench.id: 60,
                squat.id: 85,
                deadlift.id: 100
            ]
        )

        let session2 = WorkoutSession(
            startedAt: now.addingTimeInterval(-7 * day),
            endedAt: now.addingTimeInterval(-7 * day + 2800),
            maxWeightPerExercise: [
                bench.id: 70,
                squat.id: 90,
                deadlift.id: 105
            ]
        )

        let session3 = WorkoutSession(
            startedAt: now.addingTimeInterval(-1 * day),
            endedAt: now.addingTimeInterval(-1 * day + 2500),
            maxWeightPerExercise: [
                bench.id: 95,
                squat.id: 0,       // → zum Testen deiner 0-Filter-Logik
                deadlift.id: 110
            ]
        )
        
        let session4 = WorkoutSession(
            startedAt: now.addingTimeInterval(-1 * day),
            endedAt: now.addingTimeInterval(-1 * day + 2500),
            maxWeightPerExercise: [
                bench.id: 95,
                squat.id: 0,       // → zum Testen deiner 0-Filter-Logik
                deadlift.id: 110
            ]
        )
        
        let session5 = WorkoutSession(
            startedAt: now.addingTimeInterval(-1 * day),
            endedAt: now.addingTimeInterval(-1 * day + 2500),
            maxWeightPerExercise: [
                bench.id: 95,
                squat.id: 0,       // → zum Testen deiner 0-Filter-Logik
                deadlift.id: 110
            ]
        )

        return Training(
            title: "Push / Pull / Legs",
            exercises: exercises,
            sessions: [session5,session4,session3, session2, session1]
        )
    }

    static var previews: some View {

        let store = Store()

        // Trainingsspeicher füllen
        let t = sampleTraining
        store.trainings = [t]

        return NavigationStack {
            ProgressDetailView(trainingID: t.id)
                .environmentObject(store)
        }
        .previewDisplayName("Progress Detail Preview")
    }
}
