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
            
            //Mit Übungen: Mockup-Kartenlayout
            if hasExercises {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        
                        //Überscnrift der ganzen Seite
                        VStack(spacing: 0){
                            Text(training.title)
                                .font(.system(size: 34, weight: .bold))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 16)
                                .foregroundColor(.blue)
                            
                            if let last = training.sessions.first?.endedAt {
                                Text("Letztes Workout: \(last.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 16)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("Noch keine Workouts absolviert")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 16)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        
                        //Übungs-Karte
                        ForEach(training.exercises) { ex in
                            VStack(alignment: .leading, spacing: 5) {
                                
                                Text(ex.name.uppercased())
                                    .font(.title2.weight(.bold))
                                //.foregroundColor(.blue)
                                    .padding(.horizontal, 16)
                                
                                VStack(alignment: .leading, spacing: 0) {
                                    ForEach(Array(ex.sets.enumerated()), id: \.element.id) { idx, set in
                                        
                                        Divider().padding(.horizontal, 16)
                                        
                                        VStack(){
                                            Text("\(idx + 1). Satz")
                                            //.font(.headline)
                                                .fontWeight(.regular)
                                                .foregroundColor(.secondary)
                                                .font(.system(size: 14))
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                            
                                            Text("\(formatWeight(set.weightKg)) kg  x  \(set.repetition.value) Wdh.")
                                                .font(.headline)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                        }
                                        .padding(.vertical, 14)
                                        .padding(.horizontal, 16)
                                        
                                        
                                    }
                                    
                                    
                                }
                                .background(Color(.systemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                                //.shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3)
                                .padding(.horizontal, 16)
                            }
                        }
                        
                        Spacer(minLength: 80)
                    }
                }
                .scrollIndicators(.never)
                
            } else {
                // Kein Inhalt: Empty State wie in WorkoutRunView
                ScrollView {
                    VStack(spacing: 24) {
                        Text("Sie haben noch keine Übungen zu diesem Workout hinzugefügt.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                        
                        Button {
                            router.go(.addExercise(trainingID: trainingID))
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        } label: {
                            Label("Übungen hinzufügen", systemImage: "plus")
                                .font(.headline)
                                .fontWeight(.medium)
                                .frame(maxWidth: .infinity)
                            //.padding(.vertical, 16)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .clipShape(Capsule())
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
        
        // Top-Leiste: Chevron & Pencil (Pencil bleibt auch im Empty State verfügbar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { dismiss() } label: { Image(systemName: "chevron.left") }
                    .accessibilityLabel("Zurück")
            }
            
        }
        
        // Untere Leiste: „Workout starten“ nur wenn Übungen vorhanden
        .toolbar {
            if hasExercises {
                ToolbarItem(placement: .bottomBar) {
                    Button {
                        showStartAlert = true
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    } label: {
                        Text("Workout starten").fontWeight(.semibold)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(.systemBlue))
                    //.tint(.blue)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { router.go(.workoutEdit(trainingID: trainingID)) } label: {
                        Image(systemName: "pencil")
                    }
                    .accessibilityLabel("Workout bearbeiten")
                }
            }
        }
        
        // Start-Alert
        .alert("\(training.title)-Workout starten?", isPresented: $showStartAlert) {
            Button("Abbrechen", role: .cancel) { }
            Button("Starten") { router.go(.workoutRun(trainingID: trainingID)) }
                .keyboardShortcut(.defaultAction)
        } message: {
            Text("Mach dich bereit zum Trainieren")
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
