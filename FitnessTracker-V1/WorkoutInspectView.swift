import SwiftUI
import UIKit

struct WorkoutInspectView: View {
    @EnvironmentObject var store: Store
    @EnvironmentObject private var router: Router
    @Environment(\.dismiss) private var dismiss
    
    let trainingID: UUID
    @State private var showStartAlert = false
    
    private var training: Training {
        store.trainings.first(where: { $0.id == trainingID }) ?? Training(title: "Workout")
    }
    
    private var hasExercises: Bool {
        !training.exercises.isEmpty
    }
    
    var body: some View {
        ZStack {
            Color(.secondarySystemBackground).ignoresSafeArea()
            
            if hasExercises {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        
                        //Überscnrift der ganzen Seite
                        VStack(spacing: 0){
                            Text(training.title.uppercased())
                                .font(.system(size: 28, weight: .bold))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 25)
                                .foregroundColor(.blue)
                            
                            if let last = training.sessions.first?.endedAt {
                                Text("Letztes Workout: \(last.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 25)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("Noch keine Workouts absolviert")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 25)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        
                        //Übungs-Karte
                        ForEach(training.exercises) { ex in
                            VStack(alignment: .leading, spacing: 5) {
                                
                                Text(ex.name)
                                    .font(.title2.weight(.bold))
                                    .padding(.horizontal, 30)
                                
                                VStack(alignment: .leading, spacing: 0) {
                                    ForEach(Array(ex.sets.enumerated()), id: \.element.id) { idx, set in
                                        
                                        if(idx>0){
                                            Divider().padding(.horizontal, 16)
                                        }
                                        
                                        VStack(){
                                            
                                            Text("\(idx + 1). Satz")
                                                .fontWeight(.regular)
                                                .foregroundColor(.secondary)
                                                .font(.system(size: 14))
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                
                                            HStack{
                                                //Image(systemName: "dumbbell.fill")
                                                Image(systemName: "scalemass.fill")
                                                    .foregroundColor(.secondary)
                                                
                                                    
                                                Text("\(formatWeight(set.weightKg)) kg")
                                                    .fontWeight(.semibold)
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                                
                                                Image(systemName: "repeat")
                                                    .foregroundColor(.secondary)
                                                
                                                Text("\(set.repetition.value) Wdh.")
                                                    .fontWeight(.semibold)
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                            }
                                                
                                        }
                                        .padding(.vertical, 10)
                                        .padding(.horizontal, 16)
                                        
                                        
                                    }
                                    
                                    
                                }
                                .background(Color(.systemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                                .padding(.horizontal, 16)
                                
                            }
                            .padding(.vertical, 2)
                        }
                        
                        Spacer(minLength: 80)
                    }
                }
                .scrollIndicators(.never)
                
            } else {
                // Keine Übungen angelegt
                ScrollView {
                    VStack(spacing: 24) {
                        Text("Du hast noch keine Übungen zu diesem Workout hinzugefügt.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                        
                        Spacer()
                    }
                    .padding(.top, 40)
                    
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        
        // Top-Leiste: Chevron immer sichtbar
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: { Image(systemName: "chevron.left") }
                    .accessibilityLabel("Zurück")
            }
            
        }
        
        // „Workout starten“ und Pencil nur wenn Übungen vorhanden
        .toolbar {
            if hasExercises {
                ToolbarItem(placement: .bottomBar) {
                    Button {
                        showStartAlert = true
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    } label: {
                        HStack{
                            Image(systemName: "play.fill")
                            Text("Workout starten")
                                .fontWeight(.semibold)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(.systemBlue))
                    //.tint(.blue)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { router.go(.workoutEdit(trainingID: trainingID)) } label: {
                        Text("Bearbeiten")
                            .fontWeight(.semibold)
                        //Image(systemName: "pencil")
                    }
                    .accessibilityLabel("Workout bearbeiten")
                }
            }
            if !hasExercises{
                ToolbarItem(placement: .bottomBar) {
                    Button {
                        router.go(.addExercise(trainingID: trainingID))
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    } label: {
                        HStack{
                            Image(systemName: "plus")
                            Text("Übung hinzufügen")
                                .fontWeight(.semibold)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(.systemBlue))
                    //.tint(.blue)
                }
            }
        }
        
        // Start-Alert
        .alert("\(training.title)-Workout starten?", isPresented: $showStartAlert) {
            Button("Abbrechen", role: .cancel) { }
            Button("Starten") { router.go(.workoutRun(trainingID: trainingID)) }
                .keyboardShortcut(.defaultAction)
        } message: {
            Text("Mach Dich bereit zum Trainieren")
        }
    }
    
    // MARK: - Gewicht formatieren (wie in WorkoutRunView)
    private func formatWeight(_ value: Double) -> String {
        let nf = NumberFormatter()
        nf.minimumFractionDigits = 0
        nf.maximumFractionDigits = 3
        nf.decimalSeparator = ","
        return nf.string(from: NSNumber(value: value)) ?? String(value).replacingOccurrences(of: ".", with: ",")
    }
}

// MARK: - Previews

fileprivate extension Training {
    /// Beispiel-Training MIT Übungen für Previews
    static var previewWithExercises: Training {
        let sets = [
            SetEntry(weightKg: 80.25, repetition: Repetition(value: 8)),
            SetEntry(weightKg: 75, repetition: Repetition(value: 10)),
            SetEntry(weightKg: 70, repetition: Repetition(value: 12))
        ]

        let exercise = Exercise(
            name: "Bankdrücken",
            sets: sets
        )
        
        let sets2 = [
            SetEntry(weightKg: 80, repetition: Repetition(value: 8)),
            SetEntry(weightKg: 75, repetition: Repetition(value: 10)),
            SetEntry(weightKg: 70, repetition: Repetition(value: 12))
        ]

        let exercise2 = Exercise(
            name: "Brustpresse",
            sets: sets2
        )
        
        let sets3 = [
            SetEntry(weightKg: 80, repetition: Repetition(value: 8)),
            SetEntry(weightKg: 75, repetition: Repetition(value: 10)),
            SetEntry(weightKg: 70, repetition: Repetition(value: 12))
        ]

        let exercise3 = Exercise(
            name: "Butterfly",
            sets: sets2
        )

        var t = Training(title: "Push", exercises: [exercise, exercise2, exercise3])
        return t
    }

    /// Beispiel-Training OHNE Übungen (Empty State)
    static var previewEmpty: Training {
        Training(title: "Neues Workout")
    }
}


/// MARK: - Preview 1: iPhone 15 Pro — Light Mode — mit Übungen
#Preview("mit Übungen (Light)") {
    let store = Store()
    let router = Router()

    let training = Training.previewWithExercises
    store.trainings = [training]

    return NavigationStack {
        WorkoutInspectView(trainingID: training.id)
            .environmentObject(store)
            .environmentObject(router)
    }
    .preferredColorScheme(.light)
}


/// MARK: - Preview 2: iPhone 15 Pro — Dark Mode — mit Übungen
#Preview("mit Übungen (Dark)") {
    let store = Store()
    let router = Router()

    let training = Training.previewWithExercises
    store.trainings = [training]

    return NavigationStack {
        WorkoutInspectView(trainingID: training.id)
            .environmentObject(store)
            .environmentObject(router)
    }
    .preferredColorScheme(.dark)
}


/// MARK: - Preview 3: iPhone SE — Empty State
#Preview("ohne Übungen (Light)") {
    let store = Store()
    let router = Router()

    let training = Training.previewEmpty
    store.trainings = [training]

    return NavigationStack {
        WorkoutInspectView(trainingID: training.id)
            .environmentObject(store)
            .environmentObject(router)
    }
}
