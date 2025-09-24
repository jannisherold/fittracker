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
                        Text("Noch keine Workouts angelegt.")
                            .foregroundStyle(.secondary)
                        /*Text("Lege in „Workout“ ein Training an und starte Sessions – dann erscheinen hier deine Verläufe.")
                            .font(.subheadline)
                            .foregroundStyle(.tertiary)*/
                    }
                } else {
                    ForEach(store.trainings) { t in
                        Section {
                            NavigationLink {
                                ProgressDetailView(trainingID: t.id)
                            } label: {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(t.title)
                                        .font(.headline)
                                    if let last = t.sessions.first?.endedAt {
                                        Text("Letztes Training: \(last.formatted(date: .abbreviated, time: .omitted))")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    } else {
                                        Text("Noch keine Trainings absolviert")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Progress")
            .listStyle(.insetGrouped)
            .listSectionSpacing(.compact)
            
        }
    }
}
