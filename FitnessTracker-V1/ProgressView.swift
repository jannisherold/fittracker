import SwiftUI

/// Einstieg in den Progress-Tab:
/// Zeigt alle Workouts an. Tippt man eines an, geht es zur Trainings-Progress-Ansicht.
struct ProgressView: View {
    @EnvironmentObject var store: Store
    @State private var showInfo = false

    // NEU: Zustände für auf-/zugeklappte Sections
    @State private var isKraftExpanded = true
    @State private var isKoerpergewichtExpanded = false
    @State private var isFrequenzExpanded = false
    @State private var isHistorieExpanded = false
    
    // Alle Sessions aller Trainings, global nach Datum sortiert (neueste oben)
    private var sessionHistory: [(training: Training, session: WorkoutSession)] {
        store.trainings
            .flatMap { training in
                training.sessions.map { session in
                    (training: training, session: session)
                }
            }
            .sorted { lhs, rhs in
                lhs.session.endedAt > rhs.session.endedAt
            }
    }

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
                                ProgressStrenghtDetailView(trainingID: t.id)
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
                        iconName: "dumbbell.fill",
                        isExpanded: $isKraftExpanded
                    )
                }

                // MARK: - Körpergewicht
                Section(isExpanded: $isKoerpergewichtExpanded) {
                   
                            NavigationLink {
                                ProgressBodyweightView()
                            } label: {
                                Text("Logbuch")
                                    .font(.headline)
                                    .padding(.vertical, 2)
                            }
                        
                } header: {
                    CollapsibleSectionHeader(
                        title: "Körpergewicht",
                        iconName: "person.fill",
                        isExpanded: $isKoerpergewichtExpanded
                    )
                }
                
                // MARK: - Frequenz
                Section(isExpanded: $isFrequenzExpanded) {
                    
                    NavigationLink {
                        ProgressFrequencyView()
                    } label: {
                        Text("Analyse")
                            .font(.headline)
                            .padding(.vertical, 2)
                    }
                    
                } header: {
                    CollapsibleSectionHeader(
                        title: "Trainingsfrequenz",
                        iconName: "repeat",
                        isExpanded: $isFrequenzExpanded
                    )
                }

                // MARK: - Trainingshistorie
                Section(isExpanded: $isHistorieExpanded) {
                    if sessionHistory.isEmpty {
                        Text("Noch keine Workouts absolviert.")
                            .foregroundStyle(.secondary)
                    } else {
                        // Nur die 3 neuesten Sessions anzeigen
                        let recentSessions = Array(sessionHistory.prefix(3))

                        ForEach(recentSessions, id: \.session.id) { item in
                            NavigationLink {
                                // Deine bestehende Zeitreise-Detail-View
                                ProgressHistoryDetailView(
                                    trainingID: item.training.id,
                                    sessionID: item.session.id
                                )
                            } label: {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.training.title)
                                        .font(.headline)
                                    
                                    Text(item.session.endedAt.formatted(date: .abbreviated, time: .omitted))
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 2)
                            }
                        }

                    
                        // Button "Alle Sessions" -> vollständige Liste
                        if sessionHistory.count > 3 {
                            ZStack {
                                // Unsichtbarer NavigationLink (macht die Zelle tappbar & navigiert)
                                NavigationLink {
                                    ProgressHistoryList()
                                } label: {
                                    EmptyView()
                                }
                                .opacity(0) // Chevron & Standard-Label verschwinden

                                // Dein sichtbarer, chevron-freier Inhalt
                                HStack {
                                    Spacer()
                                    Text("Alle Sessions")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(.secondary) // falls du ihn "buttoniger" willst
                                    Spacer()
                                }
                                .padding(.vertical, 8)
                            }
                        }

                    }
                } header: {
                    CollapsibleSectionHeader(
                        title: "Trainingshistorie",
                        iconName: "clock.arrow.circlepath",
                        isExpanded: $isHistorieExpanded
                    )
                }

            }
            .navigationDestination(for: Training.ID.self) { id in
                ProgressStrenghtDetailView(trainingID: id)  // wird jetzt erst beim Tippen erstellt
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
    let iconName: String?
    @Binding var isExpanded: Bool

    var body: some View {
        HStack(spacing: 8) {
            if let iconName = iconName {
                Image(systemName: iconName)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.secondary)
            }

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
