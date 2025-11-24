import SwiftUI

/// Einstieg in den Progress-Tab:
/// Zeigt alle Workouts an. Tippt man eines an, geht es zur Trainings-Progress-Ansicht.
struct ProgressView: View {
    @EnvironmentObject var store: Store
    @State private var showInfo = false

    // NEU: Zustände für auf-/zugeklappte Sections
    @State private var isKraftExpanded = true
    @State private var isKoerpergewichtExpanded = false
    @State private var isHistorieExpanded = false

    var body: some View {
        NavigationStack {
            List {

                // MARK: - Kraft
                Section(isExpanded: $isKraftExpanded) {
                    if store.trainings.isEmpty {
                        Text("Noch keine Workouts angelegt.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(store.trainings) { t in
                            NavigationLink {
                                ProgressDetailView(trainingID: t.id)
                            } label: {
                                Text(t.title)
                                    .font(.headline)
                                    .padding(.vertical, 2)
                            }
                        }
                    }
                } header: {
                    CollapsibleSectionHeader(
                        title: "Kraft",
                        isExpanded: $isKraftExpanded
                    )
                }

                // MARK: - Körpergewicht
                Section(isExpanded: $isKoerpergewichtExpanded) {
                    Text("Dies sind Platzhalter. Wir füllen die Funktionen später.")
                } header: {
                    CollapsibleSectionHeader(
                        title: "Körpergewicht",
                        isExpanded: $isKoerpergewichtExpanded
                    )
                }

                // MARK: - Trainingshistorie
                Section(isExpanded: $isHistorieExpanded) {
                    if store.trainings.isEmpty {
                        Text("Noch keine Workouts angelegt.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(store.trainings) { t in
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
                } header: {
                    CollapsibleSectionHeader(
                        title: "Trainingshistorie",
                        isExpanded: $isHistorieExpanded
                    )
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

// MARK: - Header wie in Apple Notes (Titel + Chevron, klickbar)

private struct CollapsibleSectionHeader: View {
    let title: String
    @Binding var isExpanded: Bool

    var body: some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.system(size: 22, weight: .semibold))   // H2-ähnlich
                .foregroundColor(.primary)                     // Schwarz

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 16, weight: .semibold))    // größer, kräftig
                .foregroundColor(.primary)                     // ebenfalls Schwarz
                .rotationEffect(.degrees(isExpanded ? 90 : 0))
                .animation(.easeInOut(duration: 0.2), value: isExpanded)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut) {
                isExpanded.toggle()
            }
        }
        .padding(.vertical, 4)  // kompakter, wirkt mehr nach Überschrift
    }
}

