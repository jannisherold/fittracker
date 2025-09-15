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
                        .listRowInsets(EdgeInsets(top: 16, leading: 8, bottom: 0, trailing: 8)) //Leading und Trailing, Abstand von Notes zum Rand der Liste links und rechts
                    
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

// MARK: - Einzelner Satz als Checklisten-Zeile
private struct SetRow: View {
    @EnvironmentObject var store: Store
    let trainingID: UUID
    let exerciseID: UUID
    let set: SetEntry

    @State private var tempWeight: Double = 0
    @State private var tempReps: Int = 0

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

            // Gewicht + Wdh. kompakt editieren
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("\(Int(set.weightKg)) kg")
                        .fontWeight(.semibold)
                    Spacer()
                    Text("\(set.repetition.value) Whd.")
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 16) {
                    Stepper(
                        "",
                        value: Binding(
                            get: { Int(tempWeightRounded) },
                            set: { new in
                                store.updateSet(
                                    in: trainingID,
                                    exerciseID: exerciseID,
                                    setID: set.id,
                                    weight: Double(new)
                                )
                            }
                        ),
                        in: 0...500
                    )
                    .labelsHidden()
                    .frame(width: 120)

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
            tempWeight = set.weightKg
            tempReps = set.repetition.value
        }
        .onChange(of: set.weightKg) { tempWeight = set.weightKg }
        .onChange(of: set.repetition.value) { tempReps = set.repetition.value }
        .opacity(set.isDone ? 0.5 : 1.0)
        .animation(.default, value: set.isDone)
    }

    private var tempWeightRounded: Double {
        // falls du 2.5er Schritte willst -> hier runden
        (set.weightKg * 1).rounded() / 1
    }
}
