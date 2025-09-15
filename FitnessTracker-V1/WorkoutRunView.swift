import SwiftUI

struct WorkoutRunView: View {
    @EnvironmentObject var store: Store
    let trainingID: UUID
    
    @State private var showResetConfirm = false

    var body: some View {
        List {
            ForEach(training.exercises) { ex in
                Section(
                    header: Text(ex.name.uppercased()) //Titel der Übungen
                        .font(.title2)           // Größe
                        .fontWeight(.bold)       // Gewichtung
                        .foregroundColor(.blue)  // Farbe
                ) {
                    notesEditor(for: ex.id)
                        //Leading und Trailing, Abstand von Notes zum Rand der Liste links und rechts
                        .listRowInsets(EdgeInsets(top: 16, leading: 8, bottom: 0, trailing: 8))
                    
                    ForEach(ex.sets) { set in
                        SetRow(
                            trainingID: trainingID,
                            exerciseID: ex.id,
                            set: set
                        )
                    }
                }
            }
        }
        .navigationTitle(training.title)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showResetConfirm = true
                } label: {
                    Label("Session zurücksetzen", systemImage: "arrow.counterclockwise")
                }
            }
        }
        .confirmationDialog(
            "Session zurücksetzen?",
            isPresented: $showResetConfirm,
            titleVisibility: .visible
        ) {
            Button("Alle Häkchen entfernen", role: .destructive) {
                store.resetSession(trainingID: trainingID)
            }
            Button("Abbrechen", role: .cancel) { }
        }
    }

    // MARK: - Lookup
    private var training: Training {
        store.trainings.first(where: { $0.id == trainingID }) ?? Training(title: "Training")
    }
    
    // MARK: - Subview: Notizen
    @ViewBuilder
    private func notesEditor(for exerciseID: UUID) -> some View {
        // Binding direkt in den Store (sicher & performant)
        let binding = Binding<String>(
            get: {
                guard let t = store.trainings.firstIndex(where: { $0.id == trainingID }),
                      let e = store.trainings[t].exercises.firstIndex(where: { $0.id == exerciseID })
                else { return "" }
                return store.trainings[t].exercises[e].notes
            },
            set: { newValue in
                store.updateExerciseNotes(trainingID: trainingID, exerciseID: exerciseID, notes: newValue)
            }
        )

        NotesEditor(text: binding)

    }
}

// MARK: - NotesEditor mit dynamischer Höhe + Placeholder
private struct NotesEditor: View {
    @Binding var text: String
    @State private var dynamicHeight: CGFloat = 0

    private var oneLineHeight: CGFloat {
        UIFont.preferredFont(forTextStyle: .body).lineHeight + 6
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text("Notizen zur Übung hinzufügen")
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 10)
            }
            GrowingTextView(text: $text, calculatedHeight: $dynamicHeight)
                .frame(minHeight: max(dynamicHeight, oneLineHeight),
                       maxHeight: .infinity)
                .padding(10)
        }
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - UIKit-Bridge: automatisch wachsende TextView
private struct GrowingTextView: UIViewRepresentable {
    @Binding var text: String
    @Binding var calculatedHeight: CGFloat

    func makeUIView(context: Context) -> UITextView {
        let tv = UITextView()
        tv.isScrollEnabled = false
        tv.backgroundColor = .clear
        tv.font = .preferredFont(forTextStyle: .body)
        tv.textContainerInset = .zero
        tv.textContainer.lineFragmentPadding = 0
        tv.delegate = context.coordinator
        return tv
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text { uiView.text = text }
        recalcHeight(uiView)
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    private func recalcHeight(_ uiView: UITextView) {
        DispatchQueue.main.async {
            let fitting = uiView.sizeThatFits(
                CGSize(width: uiView.bounds.width, height: .greatestFiniteMagnitude)
            )
            if abs(calculatedHeight - fitting.height) > 0.5 {
                calculatedHeight = fitting.height
            }
        }
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: GrowingTextView
        init(_ parent: GrowingTextView) { self.parent = parent }

        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
            parent.recalcHeight(textView)
        }
    }
}


// Kleines Hilfs-View für TextEditor mit Placeholder
private struct ZstackWithPlaceholder: View {
    @Binding var text: String
    init(text: Binding<String>) { self._text = text }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text("Notizen zur Übung hinzufügen")
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 8)
            }
            TextEditor(text: $text)
                .frame(minHeight: 90)
                .padding(6)
        }
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}


// MARK: - Einzelner Satz als Checklisten-Zeile (mit Rad für Gewicht)
private struct SetRow: View {
    @EnvironmentObject var store: Store
    let trainingID: UUID
    let exerciseID: UUID
    let set: SetEntry

    // Reps bleiben als Stepper
    @State private var tempReps: Int = 0

    // Neues Gewichtssystem: zwei Räder
    @State private var weightInt: Int = 0                   // kg vor dem Komma
    @State private var weightFracIndex: Int = 0             // Index in 0.125-kg-Schritten
    private let fracSteps: [Double] = [0.0, 0.125, 0.25, 0.375, 0.5, 0.625, 0.75, 0.875]

    private var combinedWeight: Double {
        Double(weightInt) + fracSteps[weightFracIndex]
    }

    var body: some View {
        
        
        HStack(spacing: 12) {
            
            // Checkbox
            Button {
                store.toggleSetDone(in: trainingID, exerciseID: exerciseID, setID: set.id)
            } label: {
                Image(systemName: set.isDone ? "checkmark.circle.fill" : "circle")
                    .imageScale(.large)
            }
            .buttonStyle(.plain)
                
              
           
            
            // Gewicht (mit 2 Rädern) + Reps (Stepper)
            VStack(alignment: .leading, spacing: 4) {
                
                
                //Zeile mit Gewicht und Anzahl der Wdh.
                HStack {
                    Text("\(combinedWeight, specifier: "%.3f") kg")
                        .fontWeight(.semibold)
                    Spacer()
                    Text("\(tempReps) Whd.")
                        .fontWeight(.semibold)
                        //.foregroundStyle(.secondary)
                }

                
                
                //Zeile mit Wheel und +/-
                HStack(spacing: 16) {

                    // --- Gewicht mit 2 Rädern ---
                    HStack(spacing: 2) {
                        // Rad für kg (0...500)
                        Picker("", selection: $weightInt) {
                            ForEach(0...500, id: \.self) { Text("\($0)") }
                        }
                        .pickerStyle(.wheel)
                        .labelsHidden()
                        .frame(width: 60, height: 92)
                        .clipped()

                        Text(",")
                            .font(.headline)
                            .foregroundStyle(.secondary)

                        // Rad für Nachkommastellen (0, 125, 250, ... 875)
                        Picker("", selection: $weightFracIndex) {
                            ForEach(0..<fracSteps.count, id: \.self) { idx in
                                Text(fractionLabel(for: fracSteps[idx])) // zeigt „000“, „125“, ...
                            }
                        }
                        .pickerStyle(.wheel)
                        .labelsHidden()
                        .frame(width: 72, height: 92)
                        .clipped()
                    }
                    .onChange(of: weightInt) { _ in
                        pushWeight()
                    }
                    .onChange(of: weightFracIndex) { _ in
                        pushWeight()
                    }
                    // -----------------------------

                    
                    
                    Spacer()
                    
                    
                    
                    // Reps ändern mit Stepper
                    Stepper(
                        "",
                        value: Binding(
                            get: { tempReps },
                            set: { new in
                                store.updateSet(
                                    in: trainingID,
                                    exerciseID: exerciseID,
                                    setID: set.id,
                                    reps: new
                                )
                            }
                        ),
                        in: 1...50
                    )
                    .labelsHidden()
                    .frame(width: 90)
                }
                .font(.callout)
                .foregroundStyle(.secondary)
            }
            
            
        }
        
        
        .onAppear {
            // Startwerte aus dem Set übernehmen
            let intPart = max(0, min(500, Int(floor(set.weightKg))))
            let frac = max(0.0, set.weightKg - Double(intPart))
            weightInt = intPart
            weightFracIndex = closestFracIndex(to: frac)
            tempReps = set.repetition.value
        }
        .onChange(of: set.weightKg) { new in
            // falls extern geändert wurde, Räder nachziehen
            let intPart = max(0, min(500, Int(floor(new))))
            let frac = max(0.0, new - Double(intPart))
            weightInt = intPart
            weightFracIndex = closestFracIndex(to: frac)
        }
        .onChange(of: set.repetition.value) { tempReps = set.repetition.value }
        .opacity(set.isDone ? 0.5 : 1.0)
        .animation(.default, value: set.isDone)
    }

    // MARK: - Helpers
    private func pushWeight() {
        store.updateSet(
            in: trainingID,
            exerciseID: exerciseID,
            setID: set.id,
            weight: combinedWeight
        )
    }

    private func closestFracIndex(to value: Double) -> Int {
        var best = 0
        var bestDelta = Double.greatestFiniteMagnitude
        for (i, v) in fracSteps.enumerated() {
            let d = abs(v - value)
            if d < bestDelta { best = i; bestDelta = d }
        }
        return best
    }

    private func fractionLabel(for frac: Double) -> String {
        // Zeigt „000“, „125“, „250“, ..., „875“ hinter dem Komma
        let milli = Int(round(frac * 1000))
        return String(format: "%03d", milli)
    }
}

