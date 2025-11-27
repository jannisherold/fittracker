import SwiftUI
import UIKit

struct ProgressStatisticView: View {
    @EnvironmentObject var store: Store
    
    private var formattedMinutes: String {
        let minutes = store.totalTrainingMinutes
        // z.B. "1.234 Min"
        let intMinutes = Int(minutes.rounded())
        return "\(intMinutes) Minuten"
    }
    
    private var formattedWorkout: String {
        let workouts = store.totalCompletedWorkouts
        return "\(workouts) Workouts"
    }
    
    private var formattedRepetition: String {
        let reps = store.totalRepetitions
        return "\(reps) Wiederholungen"
    }
    
    private var formattedMovedWeight: String {
        // Max. 2 Nachkommastellen, aber oft reicht ein gerundeter Wert
        let kilos = store.totalMovedWeightKg
        if kilos >= 1000 {
            // Tausender als "t" abkürzen, z.B. 12.3 t
            let tons = kilos / 1000
            let formatted = String(format: "%.1f", tons)
            return "\(formatted) Tonnen"
        } else {
            let formatted = String(format: "%.0f", kilos)
            return "\(formatted) kg"
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                
                VStack{
                    Text("Deine Rekorde")
                        .font(.largeTitle.bold())
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 8)
                    
                    Text("Jeder Wiederholung zählt. Und das sieht man.")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom, 24)
                
                
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16)
                    ],
                    spacing: 16
                ) {
                    
                    
                    StatCard(
                        title: "Trainingszeit",
                        value: formattedMinutes,
                        subtitle: "investiert"
                    )
                    
                    StatCard(
                        title: "Gewicht",
                        value: formattedMovedWeight,
                        subtitle: "bewegt"
                    )
                    
                    
                    StatCard(
                        title: "",
                        value: formattedWorkout,
                        subtitle: "abgeschlossen"
                    )
                    
                    StatCard(
                        title: "",
                        value: formattedRepetition,
                        subtitle: "absolviert"
                    )
                }
                .padding(.top, 8)
                
                Spacer(minLength: 0)
            }
            .padding(.horizontal)
        }
        //.navigationTitle("Statistiken")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
                    // Gleicher „Feeling-Moment“ wie beim Workout-Ende
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    showGlobalConfettiOverlay(duration: 2.8)
                }
    }
}

private struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            
            
            Text(value)
                .font(.title2.bold())
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

#Preview {
    // kleine Preview mit Beispiel-Store
    let store = Store()
    return NavigationStack {
        ProgressStatisticView()
            .environmentObject(store)
    }
}
