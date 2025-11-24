import SwiftUI

/// Einstieg in den Progress-Tab:
/// Zeigt alle Workouts an. Tippt man eines an, geht es zur Trainings-Progress-Ansicht.
struct ProgressView: View {
    @EnvironmentObject var store: Store
    @State private var showInfo = false

    var body: some View {
        NavigationStack {
            List {
                
                Section("Kraft") {
                    
                    if store.trainings.isEmpty {
                        Section {
                            Text("Noch keine Workouts angelegt.")
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        ForEach(store.trainings) { t in
                            Section {
                                NavigationLink {
                                    ProgressDetailView(trainingID: t.id)
                                } label: {
                                    Text(t.title)
                                        .font(.headline)
                                    .padding(.vertical, 2)
                                }
                            }
                        }
                    }
                    
                }
                
                Section("Körpergewicht") {
                    Text("Dies sind Platzhalter. Wir füllen die Funktionen später.")
                }
                
                Section("Trainingshistorie") {
                    if store.trainings.isEmpty {
                        Section {
                            Text("Noch keine Workouts angelegt.")
                                .foregroundStyle(.secondary)
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
                                            Text("\(last.formatted(date: .abbreviated, time: .omitted))")
                                                .font(.subheadline)
                                                .foregroundStyle(.secondary)
                                        } else {
                                            Text("Noch keine Workouts absolviert")
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

                
                
            }
            .navigationDestination(for: Training.ID.self) { id in
                ProgressDetailView(trainingID: id)  // wird jetzt erst beim Tippen erstellt
            }
            .navigationTitle("Progress")
            .listStyle(.insetGrouped)
            .listSectionSpacing(.compact)
        }
    }
}
