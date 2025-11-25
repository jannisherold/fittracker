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

        private let formatter: NumberFormatter
        private let separator: String
        private let allowedCharacterSet: CharacterSet

        init(text: Binding<String>) {
            self.text = text

            let nf = NumberFormatter()
            nf.locale = Locale.current
            nf.numberStyle = .decimal
            nf.minimumFractionDigits = 0
            nf.maximumFractionDigits = 2
            self.formatter = nf
            self.separator = nf.decimalSeparator ?? ","

            var set = CharacterSet.decimalDigits
            set.insert(charactersIn: self.separator)
            self.allowedCharacterSet = set

            super.init()
        }

        // Wird bei jeder geplanten Änderung aufgerufen – hier begrenzen wir die Eingabe
        func textField(_ textField: UITextField,
                       shouldChangeCharactersIn range: NSRange,
                       replacementString string: String) -> Bool {

            let currentText = textField.text ?? ""

            // Löschen immer erlauben
            if string.isEmpty {
                if let swiftRange = Range(range, in: currentText) {
                    let newText = currentText.replacingCharacters(in: swiftRange, with: string)
                    text.wrappedValue = newText
                }
                return true
            }

            // Nur Ziffern + Dezimaltrennzeichen zulassen
            if string.rangeOfCharacter(from: allowedCharacterSet.inverted) != nil {
                return false
            }

            guard let swiftRange = Range(range, in: currentText) else {
                return false
            }

            let proposedText = currentText.replacingCharacters(in: swiftRange, with: string)

            // Nicht mehr als ein Dezimaltrennzeichen
            let separatorCount = proposedText.filter { String($0) == separator }.count
            if separatorCount > 1 {
                return false
            }

            // Integer- und Nachkommastellen prüfen
            let components = proposedText.components(separatedBy: separator)

            // Maximal 3 Ziffern vor dem Komma
            if let intPart = components.first, intPart.count > 3 {
                return false
            }

            // Maximal 2 Ziffern nach dem Komma
            if components.count == 2 {
                let fracPart = components[1]
                if fracPart.count > 2 {
                    return false
                }
            }

            // Zahlenbereich 0–200 prüfen
            // Für den Bereichscheck ignorieren wir ein ggf. anhängendes Dezimaltrennzeichen
            let rangeCheckText: String
            if proposedText.hasSuffix(separator) {
                rangeCheckText = String(proposedText.dropLast())
            } else {
                rangeCheckText = proposedText
            }

            if !rangeCheckText.isEmpty,
               let number = formatter.number(from: rangeCheckText) {
                let value = number.doubleValue
                if value < 0 || value > 200 {
                    return false
                }
            }

            // Wenn alles OK ist, Binding aktualisieren
            text.wrappedValue = proposedText
            return true
        }

        // Hält das Binding synchron, falls der Text anderweitig verändert wird
        func textFieldDidChangeSelection(_ textField: UITextField) {
            text.wrappedValue = textField.text ?? ""
        }
    }
}


// MARK: - Haupt-View

struct ProgressBodyweightView: View {
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
                                let _ = geo[proxy.plotAreaFrame]

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

    /// Zeigt den tatsächlichen Wert mit max. 3 Vorkommastellen und max. 2 Nachkommastellen
    private func formatKg(_ value: Double) -> String {
        // Sicherheits-Hardcap auf deinen Wertebereich
        let clamped = max(0, min(200, value))

        // denselben NumberFormatter-Stil wie oben verwenden
        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        formatter.maximumIntegerDigits = 3  // 0–999, passt zu 0–200

        if let formatted = formatter.string(from: NSNumber(value: clamped)) {
            return formatted
        }

        // Fallback, falls der Formatter unerwartet nil liefert
        if clamped.rounded() == clamped {
            return String(format: "%.0f", clamped)
        } else {
            return String(format: "%.2f", clamped)
        }
    }
}
