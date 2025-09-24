import SwiftUI

/// Einstieg in den Progress-Tab:
/// Zeigt alle Workouts an. Tippt man eines an, geht es zur Trainings-Progress-Ansicht.
struct ProgressView: View {
    @EnvironmentObject var store: Store

    var body: some View {
        NavigationStack {
            List {
                if store.trainings.isEmpty {
                    Section {
                        Text("Noch keine Workouts vorhanden.")
                            .foregroundStyle(.secondary)
                        Text("Lege in „Workout“ ein Training an und starte Sessions – dann erscheinen hier deine Verläufe.")
                            .font(.subheadline)
                            .foregroundStyle(.tertiary)
                    }
                } else {
                    ForEach(store.trainings) { t in
                        NavigationLink {
                            TrainingProgressView(trainingID: t.id)
                        } label: {
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(t.title)
                                        .font(.headline)
                                    if let last = t.sessions.first?.endedAt {
                                        Text("Letzte Session: \(last.formatted(date: .abbreviated, time: .omitted))")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    } else {
                                        Text("Noch keine Sessions")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("Progress")
        }
    }
}
