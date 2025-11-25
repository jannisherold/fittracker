import SwiftUI
import Charts
import UIKit

struct ProgressBodyweightDetailView: View {
    @EnvironmentObject var store: Store
    
    @State private var showInfo = false

    // Crosshair-State
    @State private var selectedPoint: BodyweightPoint?
    @State private var impactFeedback = UIImpactFeedbackGenerator(style: .rigid)

    // UI-State für "Körpergewicht hinzufügen"
    @State private var isAddingWeight = false
    @State private var weightInt: Int = 70
    @State private var weightFracIndex: Int = 0
    private let fracSteps: [Double] = [0.0, 0.125, 0.25, 0.375, 0.5, 0.625, 0.75, 0.875]

    @State private var showResetConfirm = false

    var body: some View {
        List {
          
            // Chart + Meta-Infos
            Section {
                if points.isEmpty {
                    Text("Noch keine Körpergewichts-Einträge.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 8)
                } else {
                    chartView

                    // Meta-Text unter der Chart (wie in ProgressStrenghtDetailView)
                    if let sp = selectedPoint {
                        Text("Gewicht: \(formatKg(sp.weight)) kg - \(sp.date.formatted(date: .abbreviated, time: .omitted))")
                            .font(.footnote)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                    } else if let last = lastPoint {
                        Text("Aktuell: \(formatKg(last.weight)) kg - \(last.date.formatted(date: .abbreviated, time: .omitted))")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Hinzufügen-Button + Wheel
            Section {
                addWeightButton

                if isAddingWeight {
                    weightPickerCard
                }
            }

            // Dezenter Reset-Button ganz unten
            if !store.bodyweightEntries.isEmpty {
                Section {
                    Button(role: .destructive) {
                        showResetConfirm = true
                    } label: {
                        Text("Daten zurücksetzen")
                            .font(.footnote)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        .navigationTitle("Körpergewicht")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Alle Körpergewichts-Daten löschen?", isPresented: $showResetConfirm) {
            Button("Löschen", role: .destructive) {
                store.resetBodyweightEntries()
                selectedPoint = nil
            }
            Button("Abbrechen", role: .cancel) {}
        } message: {
            Text("Diese Aktion kann nicht rückgängig gemacht werden.")
        }
        .onAppear {
            // Beim Öffnen: Wheel auf letzten Wert setzen (falls vorhanden)
            if let last = lastPoint {
                let intPart = max(0, min(500, Int(floor(last.weight))))
                let frac = max(0.0, last.weight - Double(intPart))
                weightInt = intPart
                weightFracIndex = closestFracIndex(to: frac)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                // Der Button zeigt/versteckt ein *normales SwiftUI*-Popover.
                Button {
                    showInfo.toggle()
                } label: {
                    Image(systemName: "info")
                }
                .accessibilityLabel("Info")
                // Das Popover ist direkt am Button verankert, kompakt und inhaltsbasiert.
                .popover(isPresented: $showInfo,
                         attachmentAnchor: .point(.topTrailing),
                         arrowEdge: .top) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Hier findest Du alle Details zu diesem Workout-Tag.")
                            .font(.body)
                            .multilineTextAlignment(.leading)
                            .lineLimit(nil)
                    }
                    .padding(16)
                    .frame(minWidth: 260, idealWidth: 300, maxWidth: 340)
                    .presentationSizing(.fitted)               // nur so groß wie der Inhalt
                    .presentationCompactAdaptation(.popover)   // iPhone bleibt Popover (kein Sheet)
                }
            }
        }
    }

    // MARK: - Chart

    private var chartView: some View {
        let data = points

        return Chart {
            ForEach(data) { p in
                LineMark(
                    x: .value("Messung", p.index),
                    y: .value("Gewicht (kg)", p.weight)
                )
                .interpolationMethod(.linear)
                .foregroundStyle(.blue)
            }

            if let sp = selectedPoint {
                RuleMark(
                    x: .value("Messung", sp.index)
                )
                .foregroundStyle(.gray)
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))

                PointMark(
                    x: .value("Messung", sp.index),
                    y: .value("Gewicht (kg)", sp.weight)
                )
                .symbolSize(80)
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
        .chartOverlay { proxy in
            GeometryReader { geo in
                Rectangle()
                    .fill(.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let frame = geo[proxy.plotAreaFrame]

                                // x-Position → Index
                                if frame.contains(value.location),
                                   let idx: Int = proxy.value(atX: value.location.x, as: Int.self) {

                                    if let nearest = data.min(by: {
                                        abs($0.index - idx) < abs($1.index - idx)
                                    }) {
                                        if nearest.index != selectedPoint?.index {
                                            impactFeedback.impactOccurred()
                                        }
                                        selectedPoint = nearest
                                    }
                                }
                            }
                            .onEnded { _ in
                                // Verhalten wie in deiner Strength-View: Crosshair wieder ausblenden
                                selectedPoint = nil
                            }
                    )
            }
        }
    }

    // MARK: - Chart Datenmodell

    private struct BodyweightPoint: Identifiable, Equatable {
        let id = UUID()
        let index: Int      // 1...N (chronologisch)
        let date: Date
        let weight: Double
    }

    /// Punkte chronologisch (älteste links, neueste rechts)
    private var points: [BodyweightPoint] {
        let chronological = store.bodyweightEntries.reversed() // neueste zuerst → umdrehen
        let values: [(Int, Date, Double)] = chronological.enumerated().map { (idx, entry) in
            (idx + 1, entry.date, entry.weightKg)
        }
        return values.map { BodyweightPoint(index: $0.0, date: $0.1, weight: $0.2) }
    }

    private var lastPoint: BodyweightPoint? {
        points.last
    }

    // MARK: - Hinzufügen-UI

    private var addWeightButton: some View {
        Button {
            withAnimation {
                isAddingWeight.toggle()
            }
        } label: {
            Label("Körpergewicht hinzufügen", systemImage: "plus")
                .fontWeight(.semibold)
        }
        .labelStyle(.titleAndIcon)
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top, 8)
    }

    private var weightPickerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Neuen Körpergewichts-Wert wählen")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 16) {
                // Wheel wie in WorkoutRunView (SetRow)
                HStack(spacing: 2) {
                    Picker("", selection: $weightInt) {
                        ForEach(0...500, id: \.self) { value in
                            Text("\(value)")
                        }
                    }
                    .pickerStyle(.wheel)
                    .labelsHidden()
                    .frame(width: 60, height: 92)
                    .clipped()

                    Text(",")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    Picker("", selection: $weightFracIndex) {
                        ForEach(0..<fracSteps.count, id: \.self) { idx in
                            Text(fractionLabel(for: fracSteps[idx]))
                        }
                    }
                    .pickerStyle(.wheel)
                    .labelsHidden()
                    .frame(width: 72, height: 92)
                    .clipped()
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 8) {
                    Text("\(formattedWeight) kg")
                        .font(.title3)
                        .fontWeight(.semibold)

                    Button {
                        saveWeight()
                    } label: {
                        Text("Speichern")
                            .fontWeight(.semibold)
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Abbrechen") {
                        withAnimation {
                            isAddingWeight = false
                        }
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }
            }
        }
        .padding(12)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }

    private var combinedWeight: Double {
        Double(weightInt) + fracSteps[weightFracIndex]
    }

    private var formattedWeight: String {
        // Gleicher Ansatz wie in WorkoutRunView (SetRow)
        let labels = ["", "125", "25", "375", "5", "625", "75", "875"]
        let suffix = labels[weightFracIndex]
        return suffix.isEmpty ? "\(weightInt)" : "\(weightInt),\(suffix)"
    }

    private func saveWeight() {
        store.addBodyweightEntry(weightKg: combinedWeight)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        withAnimation {
            isAddingWeight = false
        }
    }

    // MARK: - Helfer

    private func closestFracIndex(to value: Double) -> Int {
        var best = 0
        var bestDelta = Double.greatestFiniteMagnitude
        for (i, v) in fracSteps.enumerated() {
            let d = abs(v - value)
            if d < bestDelta {
                best = i
                bestDelta = d
            }
        }
        return best
    }

    private func fractionLabel(for frac: Double) -> String {
        let milli = Int(round(frac * 1000))
        return String(format: "%03d", milli)
    }

    /// Gleiche Anzeige-Logik wie in deiner Strength-Detail-View
    private func formatKg(_ value: Double) -> String {
        let frac = value - floor(value)
        if abs(frac) < 0.0001 { return "\(Int(value))" }
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
            return String(format: "%.1f", value)
        }
        return "\(intPart),\(label)"
    }
}

// MARK: - Preview (optional)

struct ProgressBodyweightDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let store = Store()
        // Beispiel-Daten zum Testen
        store.bodyweightEntries = [
            BodyweightEntry(date: Date().addingTimeInterval(-7*24*60*60), weightKg: 82.0),
            BodyweightEntry(date: Date().addingTimeInterval(-3*24*60*60), weightKg: 81.5),
            BodyweightEntry(date: Date().addingTimeInterval(-1*24*60*60), weightKg: 81.0)
        ]

        return NavigationStack {
            ProgressBodyweightDetailView()
                .environmentObject(store)
        }
    }
}
