import SwiftUI

/// Einstieg in den Progress-Tab:
/// Zeigt alle Workouts an. Tippt man eines an, geht es zur Trainings-Progress-Ansicht.
struct ProgressView: View {
    @EnvironmentObject var store: Store
    @State private var showInfo = false

    var body: some View {
        NavigationStack {
            List {
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
                            Text("Nach jeder Workout-Session werden die Bestwerte pro Übung gespeichert. Durch Tippen auf eines deiner Workouts bekommst du für jede Übung deinen Fortschritt visualisiert.")
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
}
