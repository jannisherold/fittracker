import SwiftUI
import UIKit

struct ProgressStatisticView: View {
    @EnvironmentObject var store: Store
    @State private var showInfo = false
    
    private var formattedMinutes: String {
        let minutes = store.totalTrainingMinutes
        // z.B. "1.234 Min"
        let intMinutes = Int(minutes.rounded())
        return "\(intMinutes)"
    }
    
    private var formattedWorkout: String {
        let workouts = store.totalCompletedWorkouts
        return "\(workouts)"
    }
    
    private var formattedRepetition: String {
        let reps = store.totalRepetitions
        return "\(reps)"
    }
    
    private var formattedMovedWeight: String {
        // Max. 2 Nachkommastellen, aber oft reicht ein gerundeter Wert
        let kilos = store.totalMovedWeightKg
        if kilos >= 1000 {
            // Tausender als "t" abkürzen, z.B. 12.3 t
            let tons = kilos / 1000
            let formatted = String(format: "%.1f", tons)
            return "\(formatted)"
        } else {
            let formatted = String(format: "%.0f", kilos)
            return "\(formatted)"
        }
    }
    
    private var formattedMovedWeightScale: String {
        // Max. 2 Nachkommastellen, aber oft reicht ein gerundeter Wert
        let kilos = store.totalMovedWeightKg
        if kilos >= 1000 {
            // Tausender als "t" abkürzen, z.B. 12.3 t
            let tons = kilos / 1000
            let formatted = String(format: "%.1f", tons)
            return "Tonnen"
        } else {
            let formatted = String(format: "%.0f", kilos)
            return "Kilogramm"
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
                    
                    
                    StatCardTwoLines(
                        value: formattedMinutes,
                        scale: "Minuten",
                        text: "trainiert"
                    )
                    
                    StatCardTwoLines(
                        value: formattedMovedWeight,
                        scale: formattedMovedWeightScale + " LAST",
                        text: "bewegt"
                    )
                    
                    StatCardTwoLines(
                        value: formattedWorkout,
                        scale: "Workouts",
                        text: "beendet"
                    )
                    
                    StatCardTwoLines(
                        value: formattedRepetition,
                        scale: "Wiederholungen",
                        text: "absolviert"
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
                    showGlobalConfettiOverlay(duration: 2.0)
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
                        Text("Wow! Hier siehst Du Deine All-time Statistiken. Darauf kannst Du wirklich stolz sein.")
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
}

private struct StatCardOneLine: View {
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

private struct StatCardTwoLines: View {
    
    let value: String
    let scale: String
    let text: String
    
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(value)
                .font(.title2.bold())
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            
            Text(scale.uppercased())
                .fontWeight(.bold)
                .font(.system(size: 14))
                .foregroundColor(.blue)
                ///.minimumScaleFactor(0.7)
                //.lineLimit(1)
            
            Text(text)
                .fontWeight(.semibold)
                .font(.system(size: 14))
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
