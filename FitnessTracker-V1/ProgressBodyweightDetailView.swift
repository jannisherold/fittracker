import SwiftUI
import Charts
import UIKit

// MARK: - UIKit-Bridge: TextField, das automatisch First Responder wird

struct FirstResponderNumberField: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField(frame: .zero)
        textField.delegate = context.coordinator
        textField.keyboardType = .decimalPad
        textField.textAlignment = .center
        textField.font = UIFont.systemFont(ofSize: 40, weight: .bold)
        textField.adjustsFontForContentSizeCategory = true
        textField.placeholder = placeholder
        textField.setContentHuggingPriority(.defaultLow, for: .horizontal)
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        // Tastatur direkt anzeigen
        DispatchQueue.main.async {
            textField.becomeFirstResponder()
        }

        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        uiView.text = text
        uiView.placeholder = placeholder
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    class Coordinator: NSObject, UITextFieldDelegate {
        var text: Binding<String>

        init(text: Binding<String>) {
            self.text = text
        }

        func textFieldDidChangeSelection(_ textField: UITextField) {
            text.wrappedValue = textField.text ?? ""
        }
    }
}


// MARK: - Haupt-View

struct ProgressBodyweightDetailView: View {
    @EnvironmentObject var store: Store
    
    @State private var showInfo = false

    // Crosshair-State
    @State private var selectedPoint: BodyweightPoint?
    @State private var impactFeedback = UIImpactFeedbackGenerator(style: .rigid)

    // UI-State für "Körpergewicht hinzufügen"
    @State private var isAddingWeight = false
    @State private var weightInput: String = ""

    init(isAddingWeight: Bool = false) {
        _isAddingWeight = State(initialValue: isAddingWeight)
    }

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
        }
        .navigationTitle("Körpergewicht")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Beim Öffnen: Eingabe mit letztem Wert vorbelegen
            if let last = lastPoint {
                weightInput = numberFormatter.string(from: NSNumber(value: last.weight)) ?? ""
            }
        }
        // Obere Toolbar: Info-Button
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showInfo.toggle()
                } label: {
                    Image(systemName: "info")
                }
                .accessibilityLabel("Info")
                .popover(isPresented: $showInfo,
                         attachmentAnchor: .point(.topTrailing),
                         arrowEdge: .top) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Hier kannst Du jederzeit Dein aktuelles Körpergewicht eintragen und die Veränderung im Chart analysieren. Tipp: Wiege Dich täglich morgens auf nüchternen Magen um sinnvoll zu vergleichen.")
                            .font(.body)
                            .multilineTextAlignment(.leading)
                            .lineLimit(nil)
                    }
                    .padding(16)
                    .frame(minWidth: 260, idealWidth: 300, maxWidth: 340)
                    .presentationSizing(.fitted)
                    .presentationCompactAdaptation(.popover)
                }
            }
        }
        // Untere Toolbar: blauer "Eintrag hinzufügen" Button
        .toolbar {
            ToolbarItem(placement: .bottomBar) {
                addWeightButton
            }
        }
        .toolbar(.hidden, for: .tabBar)
        // Sheet für die Eingabe
        .sheet(isPresented: $isAddingWeight) {
            NavigationStack {
                    HStack(spacing: 0) {
                            FirstResponderNumberField(
                                text: $weightInput,
                                placeholder: weightPlaceholder
                            )
                            .frame(height: 60)

                            Text("kg")
                                .font(.system(size: 40, weight: .bold))
                        }
                        .padding(.horizontal, 32)

                .toolbar {
                    // 1. Abbrechen
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Abbrechen") {
                            isAddingWeight = false
                        }
                    }
                    // 2. Speichern
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Speichern") {
                            saveWeight()
                            isAddingWeight = false
                        }
                        .disabled(parsedWeight == nil)
                        .foregroundColor(.blue)
                    }
                }
            }
            .presentationDetents([.height(150)])
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
            AxisMarks { _ in
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

                               
                                  if let idx: Int = proxy.value(atX: value.location.x, as: Int.self) {

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

    // MARK: - Button unten

    private var addWeightButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            // Beim Öffnen des Sheets Eingabe mit letztem Wert vorbelegen
            if let last = lastPoint {
                weightInput = numberFormatter.string(from: NSNumber(value: last.weight)) ?? ""
            } else {
                weightInput = ""
            }
            isAddingWeight = true
        } label: {
            Text("Eintrag hinzufügen")
                .fontWeight(.semibold)
        }
        .buttonStyle(.borderedProminent)
        .tint(Color(.systemBlue))
    }

    // MARK: - Parsing & Formatierung

    private var numberFormatter: NumberFormatter {
        let nf = NumberFormatter()
        nf.locale = Locale.current
        nf.numberStyle = .decimal
        nf.minimumFractionDigits = 0
        nf.maximumFractionDigits = 2
        return nf
    }

    /// Versucht, die Texteingabe in einen Double-Wert zu parsen
    private var parsedWeight: Double? {
        guard !weightInput.isEmpty else { return nil }
        guard let number = numberFormatter.number(from: weightInput) else { return nil }
        return number.doubleValue
    }

    private func formattedParsedWeight(_ value: Double) -> String {
        numberFormatter.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
    }

    /// Placeholder, wenn das Feld leer ist
    private var weightPlaceholder: String {
        if let last = lastPoint {
            return (formattedParsedWeight(last.weight))
        } else {
            let zero = numberFormatter.string(from: 0) ?? "0,00"
            return (zero)
        }
    }

    private func saveWeight() {
        guard var weight = parsedWeight else { return }

        // Begrenze auf 0–200 kg und runde auf 2 Nachkommastellen
        weight = max(0, min(200, weight))
        weight = (weight * 100).rounded() / 100

        store.addBodyweightEntry(weightKg: weight)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    // MARK: - Anzeige-Helfer für Chart

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
