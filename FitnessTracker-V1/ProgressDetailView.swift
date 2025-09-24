import SwiftUI
import Charts

/// Zeigt pro Übung eines Workouts einen kleinen Verlauf (X = Sessions, Y = Gewicht).
struct ProgressDetailView: View {
    @EnvironmentObject var store: Store

    let trainingID: UUID

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

                            if points(for: ex.id).isEmpty {
                                Text("Noch keine Daten aus Sessions")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            } else {
                                Chart(points(for: ex.id)) { p in
                                    LineMark(
                                        x: .value("Session", p.index),
                                        y: .value("Gewicht (kg)", p.weight)
                                    )
                                    .interpolationMethod(.catmullRom)
                                    .foregroundStyle(.blue)

                                    PointMark(
                                        x: .value("Session", p.index),
                                        y: .value("Gewicht (kg)", p.weight)
                                    )
                                    .foregroundStyle(.blue)
                                }
                                .chartXAxis {
                                    AxisMarks(values: .stride(by: 1)) { value in
                                        AxisGridLine()
                                        AxisTick()
                                        AxisValueLabel {
                                            if let i = value.as(Int.self) {
                                                Text(String(i))
                                            }
                                        }
                                    }
                                }
                                .chartYAxis {
                                    AxisMarks() { value in
                                        AxisGridLine()
                                        AxisTick()
                                        AxisValueLabel()
                                    }
                                }
                                .frame(height: 160)
                                .padding(.top, 4)

                                // Kleiner Meta-Block unten
                                if let last = lastPoint(for: ex.id) {
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
    private struct ExercisePoint: Identifiable {
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
