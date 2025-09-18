import SwiftUI
import UIKit

struct WorkoutRunView: View {
    @EnvironmentObject var store: Store
    let trainingID: UUID
    
    @State private var showResetConfirm = false
    @State private var expandedSetID: UUID? = nil

    // ⬇️ NEU: programmgesteuerte Navigation zur Edit-View
    @State private var goEdit = false

    var body: some View {
        if training.exercises.isEmpty {
            // --- Leerer Zustand ---
            VStack{
                Text("Sie haben noch keine Übungen zu diesem Workout hinzugefügt")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding()
                
                NavigationLink {
                    AddExerciseView(trainingID: trainingID, afterSave: .goToEdit)
                        .environmentObject(store)
                } label: {
                    Label("Übungen hinzufügen", systemImage: "plus")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle(training.title)
        } else {
            // --- Mit Übungen ---
            ZStack {
                List {
                    // Übungen + Notizen + Sets
                    ForEach(training.exercises) { ex in
                        Section(
                            header: Text(ex.name.uppercased())
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                        ) {
                            notesEditor(for: ex.id)
                                .listRowInsets(EdgeInsets(top: 10, leading: 5, bottom: 10, trailing: 5))
                            
                            ForEach(ex.sets) { set in
                                SetRow(
                                    trainingID: trainingID,
                                    exerciseID: ex.id,
                                    set: set,
                                    expandedSetID: $expandedSetID
                                )
                            }
                        }
                    }
                    
                    // ⬇️ Letzte Section: Chip-Button ohne Chevron
                    Section {
                        HStack {
                            Spacer()
                            Button {
                                goEdit = true
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "pencil")
                                        .imageScale(.large)
                                        .foregroundStyle(.secondary)
                                    Text("Workout bearbeiten")
                                        .font(.headline)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(Color(.systemBackground))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                                //.shadow(color: .black.opacity(0.06), radius: 6, y: 2)
                            }
                            .buttonStyle(.plain)
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                    .listRowBackground(Color.clear)
                }

                // ⬇️ Versteckter Link (programmgesteuerte Navigation, kein Chevron)
                NavigationLink(
                    destination: WorkoutEditView(trainingID: trainingID).environmentObject(store),
                    isActive: $goEdit
                ) { EmptyView() }
                .hidden()
            }
            .scrollDismissesKeyboard(.immediately)
            .simultaneousGesture(TapGesture().onEnded { hideKeyboard() })
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
    }

    // MARK: - Lookup
    private var training: Training {
        store.trainings.first(where: { $0.id == trainingID }) ?? Training(title: "Training")
    }
    
    // MARK: - Subview: Notizen
    @ViewBuilder
    private func notesEditor(for exerciseID: UUID) -> some View {
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

// … (NotesEditor, GrowingTextView, SetRow bleiben unverändert)


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
            GeometryReader { proxy in
                GrowingTextView(
                    text: $text,
                    calculatedHeight: $dynamicHeight,
                    fixedWidth: proxy.size.width - 20
                )
                .frame(
                    width: proxy.size.width - 20,
                    height: max(dynamicHeight, oneLineHeight)
                )
            }
            .frame(minHeight: max(dynamicHeight, oneLineHeight))
            .padding(10)
        }
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - UIKit-Bridge
private struct GrowingTextView: UIViewRepresentable {
    @Binding var text: String
    @Binding var calculatedHeight: CGFloat
    let fixedWidth: CGFloat

    func makeUIView(context: Context) -> UITextView {
        let tv = UITextView()
        tv.isScrollEnabled = false
        tv.backgroundColor = .clear
        tv.font = .preferredFont(forTextStyle: .body)
        tv.textContainerInset = .zero
        tv.textContainer.lineFragmentPadding = 0
        tv.textContainer.widthTracksTextView = true
        tv.delegate = context.coordinator
        tv.keyboardDismissMode = .interactive
        tv.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return tv
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text { uiView.text = text }
        recalcHeight(uiView)
    }

    private func recalcHeight(_ uiView: UITextView) {
        DispatchQueue.main.async {
            let fitting = uiView.sizeThatFits(
                CGSize(width: fixedWidth, height: .greatestFiniteMagnitude)
            )
            if abs(calculatedHeight - fitting.height) > 0.5 {
                calculatedHeight = fitting.height
            }
        }
    }
    
    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: GrowingTextView
        init(_ parent: GrowingTextView) { self.parent = parent }
        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
            parent.recalcHeight(textView)
        }
    }
}

// MARK: - SetRow
private struct SetRow: View {
    @EnvironmentObject var store: Store
    let trainingID: UUID
    let exerciseID: UUID
    let set: SetEntry

    @State private var tempReps: Int = 0
    @Binding var expandedSetID: UUID?
    private var isExpanded: Bool { expandedSetID == set.id }

    @State private var weightInt: Int = 0
    @State private var weightFracIndex: Int = 0
    private let fracSteps: [Double] = [0.0, 0.125, 0.25, 0.375, 0.5, 0.625, 0.75, 0.875]

    private var combinedWeight: Double { Double(weightInt) + fracSteps[weightFracIndex] }
    private var formattedWeight: String {
        let labels = ["", "125", "25", "375", "5", "625", "75", "875"]
        let suffix = labels[weightFracIndex]
        return suffix.isEmpty ? "\(weightInt)" : "\(weightInt),\(suffix)"
    }

    var body: some View {
        HStack(alignment: .top,spacing: 12) {
            Button {
                let willBeDone = !set.isDone
                store.toggleSetDone(in: trainingID, exerciseID: exerciseID, setID: set.id)
                if willBeDone {
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    withAnimation(.easeInOut) { if isExpanded { expandedSetID = nil } }
                } else {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            } label: {
                Image(systemName: set.isDone ? "checkmark.circle.fill" : "circle")
                    .imageScale(.large)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("\(formattedWeight) kg")
                        .fontWeight(.semibold)
                        .onTapGesture { withAnimation(.easeInOut) { expandedSetID = isExpanded ? nil : set.id } }
                    Spacer()
                    Text("\(tempReps) Whd.")
                        .fontWeight(.semibold)
                        .onTapGesture { withAnimation(.easeInOut) { expandedSetID = isExpanded ? nil : set.id } }
                }
                .contentShape(Rectangle())

                if isExpanded {
                    HStack(spacing: 16) {
                        HStack(spacing: 2) {
                            Picker("", selection: $weightInt) {
                                ForEach(0...500, id: \.self) { Text("\($0)") }
                            }
                            .pickerStyle(.wheel)
                            .labelsHidden()
                            .frame(width: 60, height: 92)
                            .clipped()

                            Text(",").font(.headline).foregroundStyle(.secondary)

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
                        .onChange(of: weightInt) { _ in pushWeight() }
                        .onChange(of: weightFracIndex) { _ in pushWeight() }

                        Spacer()

                        Stepper(
                            "",
                            value: Binding(
                                get: { tempReps },
                                set: { new in
                                    store.updateSet(in: trainingID, exerciseID: exerciseID, setID: set.id, reps: new)
                                }
                            ),
                            in: 0...50
                        )
                        .labelsHidden()
                        .frame(width: 90)
                    }
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .transition(.opacity)
                }
            }
        }
        .onAppear {
            let intPart = max(0, min(500, Int(floor(set.weightKg))))
            let frac = max(0.0, set.weightKg - Double(intPart))
            weightInt = intPart
            weightFracIndex = closestFracIndex(to: frac)
            tempReps = set.repetition.value
        }
        .onChange(of: set.weightKg) { new in
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
        store.updateSet(in: trainingID, exerciseID: exerciseID, setID: set.id, weight: combinedWeight)
    }

    private func closestFracIndex(to value: Double) -> Int {
        var best = 0, bestDelta = Double.greatestFiniteMagnitude
        for (i, v) in fracSteps.enumerated() {
            let d = abs(v - value)
            if d < bestDelta { best = i; bestDelta = d }
        }
        return best
    }

    private func fractionLabel(for frac: Double) -> String {
        let milli = Int(round(frac * 1000))
        return String(format: "%03d", milli)
    }
}
