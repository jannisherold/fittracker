import SwiftUI
import UIKit
import SpriteKit
import AudioToolbox


struct WorkoutRunView: View {
    @EnvironmentObject var store: Store
    @EnvironmentObject private var router: Router

    let trainingID: UUID

    // Session-Handling
    @State private var didStartSession = false
    @State private var showEndConfirm = false

    // UI-State
    @State private var expandedSetID: UUID? = nil

    var body: some View {
        if training.exercises.isEmpty {
            // --- Leerer Zustand ---
            VStack {
                Text("Du hast noch keine Übungen zu diesem Workout hinzugefügt.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding()

                NavigationLink(value: Route.addExercise(trainingID: trainingID)) {
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
            .navigationBarBackButtonHidden(true)
            .toolbar(.hidden, for: .tabBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { router.popToRoot() } label: { Image(systemName: "chevron.left") }
                        .accessibilityLabel("Zur Startansicht")
                }
            }
            .onAppear { startSessionIfNeeded() }

        } else {
            // --- Mit Übungen ---
            ZStack {
                List {
                    ForEach(training.exercises) { ex in
                        Section(
                            header: Text(ex.name.uppercased())
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                        ) {
                            notesEditor(for: ex.id)
                                .listRowInsets(EdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5))

                            ForEach(ex.sets) { set in
                                SetRow(
                                    trainingID: trainingID,
                                    exerciseID: ex.id,
                                    set: set,
                                    expandedSetID: $expandedSetID
                                )
                                .environmentObject(store)
                            }
                        }
                    }
                }
            }
            .scrollDismissesKeyboard(.immediately)
            .simultaneousGesture(TapGesture().onEnded { hideKeyboard() })
            .navigationBarBackButtonHidden(true)
            .toolbar(.hidden, for: .tabBar)
            // ✅ Eigener Titelbereich: Workoutname + Stoppuhr (aktualisiert sich jede Sekunde)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 6) {
                        Text(training.title)
                            .font(.headline)
                        if let start = training.currentSessionStart {
                            TimelineView(.periodic(from: .now, by: 1)) { _ in
                                Text("- \(formatElapsed(since: start))")
                                    .monospacedDigit()
                                    .font(.headline)
                            }
                        }
                    }
                }
                // Links: Chevron -> „Workout beenden?“-Dialog
                ToolbarItem(placement: .topBarLeading) {
                    Button { showEndConfirm = true } label: { Image(systemName: "chevron.left") }
                        .accessibilityLabel("Workout beenden")
                }
            }
            // Untere Leiste: „Workout beenden“ (unverändert)
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
                    Button(action: { showEndConfirm = true }) {
                        Text("Workout beenden")
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                    }
                }
            }
            .onAppear {
                startSessionIfNeeded()
                if expandedSetID == nil,
                   let firstExercise = training.exercises.first,
                   let firstSet = firstExercise.sets.first {
                    expandedSetID = firstSet.id
                }
            }
            .alert("Workout beenden?", isPresented: $showEndConfirm) {
                Button("Beenden", role: .destructive) { endSessionAndLeave() }
                Button("Abbrechen", role: .cancel) { }
            } message: {
                Text("Das Training wird beendet und die Werte je Übung gespeichert.")
            }
        }
    }

    // MARK: - Lookup
    private var training: Training {
        store.trainings.first(where: { $0.id == trainingID }) ?? Training(title: "Training")
    }

    // MARK: - Session
    private func startSessionIfNeeded() {
        guard !didStartSession else { return }
        didStartSession = true
        // Setzt alle Sätze auf „nicht erledigt“ und setzt currentSessionStart
        store.beginSession(trainingID: trainingID)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    private func playSuccessSound() {
        //wooosh Mail versenden
        //AudioServicesPlaySystemSound(1001)
        
        //wiuuuu (Mail
        //AudioServicesPlaySystemSound(1003)
        
        //düdüdüm
        //AudioServicesPlaySystemSound(1007)
        
        //Trompete
        AudioServicesPlaySystemSound(1025)
        
        //Ding
        //AudioServicesPlaySystemSound(1054)
        
    }

    private func endSessionAndLeave() {
        store.endSession(trainingID: trainingID)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        showGlobalConfettiOverlay(duration: 2.0)
        playSuccessSound()
        router.popToRoot()
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

    // MARK: - Timer-Format
    private func formatElapsed(since start: Date) -> String {
        let total = max(0, Int(Date().timeIntervalSince(start)))
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 {
            // HH:mm:ss
            return String(format: "%02d:%02d:%02d", h, m, s)
        } else {
            // mm:ss
            return String(format: "%02d:%02d", m, s)
        }
    }

    // MARK: - Keyboard
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil, from: nil, for: nil)
    }
}

// MARK: - NotesEditor & GrowingTextView & SetRow & Konfetti (unverändert)
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
        .clipShape(RoundedRectangle(cornerRadius:22))
    }
}

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
        HStack(alignment: .top, spacing: 12) {
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
                    Text("\(tempReps) Wdh.")
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
                        .onChange(of: weightInt) { _ in pushWeight() }
                        .onChange(of: weightFracIndex) { _ in pushWeight() }

                        Spacer()

                        Stepper(
                            "",
                            value: Binding(
                                get: { tempReps },
                                set: { new in
                                    store.updateSet(in: trainingID, exerciseID: exerciseID, setID: set.id, reps: new)
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                }
                            ),
                            in: 0...50
                        )
                        .labelsHidden()
                        .frame(width: 90)
                    }
                    .font(.callout)
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
        .onChange(of: set.repetition.value) {
            tempReps = set.repetition.value
        }
        .opacity(set.isDone ? 0.5 : 1.0)
        .animation(.default, value: set.isDone)
    }

    private func pushWeight() {
        store.updateSet(in: trainingID, exerciseID: exerciseID, setID: set.id, weight: combinedWeight)
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
        let milli = Int(round(frac * 1000))
        return String(format: "%03d", milli)
    }
}

// MARK: - Apple-only Konfetti-Overlay (SpriteKit)
private final class ConfettiScene: SKScene {
    private let colors: [SKColor] = [.systemPink, .systemBlue, .systemGreen, .systemOrange, .systemYellow, .systemPurple]

    override func didMove(to view: SKView) {
        backgroundColor = .clear
        let spawn = SKAction.run { [weak self] in self?.spawnConfetti() }
        run(.repeatForever(.sequence([spawn, .wait(forDuration: 0.06)])))
    }

    private func spawnConfetti() {
        let x = CGFloat.random(in: 0...size.width)
        let start = CGPoint(x: x, y: size.height + 20)

        let w = CGFloat.random(in: 6...10)
        let h = CGFloat.random(in: 12...18)
        let node = SKShapeNode(rectOf: CGSize(width: w, height: h), cornerRadius: 2)
        node.fillColor = colors.randomElement() ?? .white
        node.strokeColor = .clear
        node.position = start
        node.alpha = 0.95
        addChild(node)

        let dur = TimeInterval.random(in: 2.2...3.4)
        let end = CGPoint(x: x + CGFloat.random(in: -120...120), y: -40)
        node.run(.sequence([.group([.move(to: end, duration: dur),
                                    .rotate(byAngle: .pi * CGFloat.random(in: 2...5), duration: dur)]),
                            .fadeOut(withDuration: 0.25),
                            .removeFromParent()]))
    }
}

private func showGlobalConfettiOverlay(duration: TimeInterval = 1.0) {
    guard
        let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
        let window = scene.windows.first(where: { $0.isKeyWindow })
    else { return }

    let skView = SKView(frame: window.bounds)
    skView.backgroundColor = .clear
    skView.isUserInteractionEnabled = false
    skView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    skView.accessibilityIdentifier = "GlobalConfettiOverlay"

    let confetti = ConfettiScene(size: skView.bounds.size)
    confetti.scaleMode = .resizeFill
    confetti.backgroundColor = .clear
    skView.presentScene(confetti)

    window.addSubview(skView)

    UIView.animate(withDuration: 0.25, delay: duration, options: [.beginFromCurrentState, .curveEaseOut], animations: {
        skView.alpha = 0
    }, completion: { _ in
        skView.removeFromSuperview()
    })
    

    
    
}

// MARK: - Preview Testdaten

extension SetEntry {
    static func sample(weight: Double, reps: Int, done: Bool = false) -> SetEntry {
        SetEntry(
            weightKg: weight,
            repetition: Repetition(value: reps),
            isDone: done
        )
    }
}

extension Exercise {
    static var sampleBankdruecken: Exercise {
        Exercise(
            name: "Bankdrücken",
            sets: [
                .sample(weight: 60, reps: 10),
                .sample(weight: 70, reps: 8),
                .sample(weight: 75, reps: 6, done: true)
            ],
            notes: "Ellbogen nah am Körper halten."
        )
    }

    static var sampleSchulterdruecken: Exercise {
        Exercise(
            name: "Schulterdrücken",
            sets: [
                .sample(weight: 30, reps: 12),
                .sample(weight: 35, reps: 10),
                .sample(weight: 40, reps: 8)
            ],
            notes: "Core anspannen. Und ganz viele andere Notizen damit getestet wird wie mehrere Zeilen aussehen"
        )
    }
}

extension Training {
    static var sampleWorkoutRun: Training {
        Training(
            title: "Push Day",
            date: Date(),
            exercises: [
                .sampleBankdruecken,
                .sampleSchulterdruecken
            ],
            sessions: [],                 // für diese View egal
            currentSessionStart: Date()   // damit der Timer im Titel läuft
        )
    }
}

// MARK: - Preview

#if DEBUG
struct WorkoutRunView_Previews: PreviewProvider {
    static var previews: some View {
        // Beispiel-Store mit einem Training
        let store = Store()
        store.trainings = [.sampleWorkoutRun]

        let trainingID = store.trainings[0].id

        return NavigationStack {
            WorkoutRunView(trainingID: trainingID)
                .environmentObject(store)
                .environmentObject(Router())
        }
    }
}
#endif
