import SwiftUI

struct ProgressStatisticView: View {
    @EnvironmentObject var store: Store
    
    private var formattedMinutes: String {
        let minutes = store.totalTrainingMinutes
        // z.B. "1.234 Min"
        let intMinutes = Int(minutes.rounded())
        return "\(intMinutes) Min"
    }
    
    private var formattedMovedWeight: String {
        // Max. 2 Nachkommastellen, aber oft reicht ein gerundeter Wert
        let kilos = store.totalMovedWeightKg
        if kilos >= 1000 {
            // Tausender als "t" abkürzen, z.B. 12.3 t
            let tons = kilos / 1000
            let formatted = String(format: "%.1f", tons)
            return "\(formatted) t"
        } else {
            let formatted = String(format: "%.0f", kilos)
            return "\(formatted) kg"
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                
                VStack{
                    Text("Statistik")
                        .font(.largeTitle.bold())
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 8)
                    
                    Text("All-Time Statistiken deiner Trainingsleistungen.")
                        .font(.subheadline)
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
                        title: "Workouts",
                        value: "\(store.totalCompletedWorkouts)",
                        subtitle: "absolviert"
                    )
                    
                    StatCard(
                        title: "Trainingszeit",
                        value: formattedMinutes,
                        subtitle: "insgesamt"
                    )
                    
                    StatCard(
                        title: "Bewegtes Gewicht",
                        value: formattedMovedWeight,
                        subtitle: "all time"
                    )
                    
                    StatCard(
                        title: "Wiederholungen",
                        value: "\(store.totalRepetitions)",
                        subtitle: "gesamt"
                    )
                }
                .padding(.top, 8)
                
                Spacer(minLength: 0)
            }
            .padding(.horizontal)
        }
        .navigationTitle("Statistiken")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text(value)
                .font(.title2.bold())
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            
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
