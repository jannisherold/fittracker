import SwiftUI

/// Einstieg in den Progress-Tab:
/// Zeigt alle Workouts an. Tippt man eines an, geht es zur Trainings-Progress-Ansicht.
struct ProgressView: View {
    @EnvironmentObject var store: Store
    @State private var showInfo = false

    // NEU: Zustände für auf-/zugeklappte Sections
    @State private var isKraftExpanded = false
    @State private var isStatisticExpanded = false
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
                            .listRowBackground(Color.clear)
                    } else {
                        ForEach(store.trainings) { t in
                            NavigationLink {
                                ProgressStrenghtView(trainingID: t.id)
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
                Section(isExpanded: $isStatisticExpanded) {
                    
                            NavigationLink {
                                ProgressStatisticView()
                                
                            } label: {
                                Text("Rekorde")
                                    .font(.headline)
                                    .padding(.vertical, 2)
                            }
                } header: {
                    CollapsibleSectionHeader(
                        title: "Statistik",
                        iconName: "trophy.fill",
                        isExpanded: $isStatisticExpanded
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
                            .listRowBackground(Color.clear)
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
                                VStack(alignment: .leading, spacing: 0) {
                                    Text(item.training.title)
                                        .font(.headline)
                                    
                                    Text(item.session.endedAt.formatted(date: .abbreviated, time: .omitted))
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 0)
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
                                    /*
                                    Spacer()
                                    Text("Alle Sessions")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(.secondary) // falls du ihn "buttoniger" willst
                                    Spacer()
                                     */
                                    Image(systemName: "ellipsis")
                                        .foregroundColor(.secondary)
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
                ProgressStrenghtView(trainingID: id)  // wird jetzt erst beim Tippen erstellt
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
                    .font(.system(size: 18, weight: .semibold))
                    //.foregroundColor(.secondary)
                    .frame(width: 28, alignment: .leading)
                    .foregroundStyle(.blue)
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


#if DEBUG
struct ProgressView_Previews: PreviewProvider {
    static var previews: some View {
        let store = Store.preview

        return NavigationStack {
            ProgressView()
                .environmentObject(store)
        }
    }
}

extension Store {
    /// Beispiel-Store nur für Xcode Previews
    static var preview: Store {
        let store = Store()

        let calendar = Calendar.current
        let now = Date()

        // MARK: - Beispiel-Training: Push Day

        var push = Training(title: "Push Day")

        let pushBenchSets = [
            SetEntry(weightKg: 80, repetition: .init(value: 8), isDone: false),
            SetEntry(weightKg: 80, repetition: .init(value: 6), isDone: false)
        ]

        let pushShoulderSets = [
            SetEntry(weightKg: 50, repetition: .init(value: 10), isDone: false),
            SetEntry(weightKg: 50, repetition: .init(value: 8), isDone: false)
        ]

        let benchExercise = Exercise(name: "Bankdrücken", sets: pushBenchSets)
        let shoulderExercise = Exercise(name: "Schulterdrücken", sets: pushShoulderSets)

        push.exercises = [benchExercise, shoulderExercise]

        // Session-Snapshots für Push-Training (absolvierte Workouts)
        let pushSession1Exercises: [SessionExerciseSnapshot] = [
            SessionExerciseSnapshot(
                originalExerciseID: UUID(),
                name: "Bankdrücken",
                sets: [
                    SessionSetSnapshot(
                        originalSetID: UUID(),
                        weightKg: 80,
                        repetition: .init(value: 8),
                        isDone: true
                    ),
                    SessionSetSnapshot(
                        originalSetID: UUID(),
                        weightKg: 80,
                        repetition: .init(value: 6),
                        isDone: true
                    )
                ],
                notes: "Starkes Training 💪"
            )
        ]

        let pushSession2Exercises: [SessionExerciseSnapshot] = [
            SessionExerciseSnapshot(
                originalExerciseID: UUID(),
                name: "Schulterdrücken",
                sets: [
                    SessionSetSnapshot(
                        originalSetID: UUID(),
                        weightKg: 50,
                        repetition: .init(value: 10),
                        isDone: true
                    ),
                    SessionSetSnapshot(
                        originalSetID: UUID(),
                        weightKg: 50,
                        repetition: .init(value: 8),
                        isDone: true
                    )
                ],
                notes: "Schulter hat gut mitgemacht"
            )
        ]

        let pushSession1 = WorkoutSession(
            startedAt: calendar.date(byAdding: .minute, value: -45, to: now) ?? now,
            endedAt: now,
            maxWeightPerExercise: [
                pushSession1Exercises[0].originalExerciseID: 80
            ],
            exercises: pushSession1Exercises
        )

        let pushSession2 = WorkoutSession(
            startedAt: calendar.date(byAdding: .day, value: -2, to: now) ?? now,
            endedAt: calendar.date(byAdding: .day, value: -2, to: now) ?? now,
            maxWeightPerExercise: [
                pushSession2Exercises[0].originalExerciseID: 50
            ],
            exercises: pushSession2Exercises
        )

        push.sessions = [pushSession1, pushSession2]

        // MARK: - Beispiel-Training: Pull Day

        var pull = Training(title: "Pull Day")

        let pullRowSets = [
            SetEntry(weightKg: 90, repetition: .init(value: 8), isDone: false),
            SetEntry(weightKg: 90, repetition: .init(value: 8), isDone: false)
        ]

        let rowExercise = Exercise(name: "Rudern", sets: pullRowSets)
        pull.exercises = [rowExercise]

        let pullSessionExercises: [SessionExerciseSnapshot] = [
            SessionExerciseSnapshot(
                originalExerciseID: UUID(),
                name: "Rudern",
                sets: [
                    SessionSetSnapshot(
                        originalSetID: UUID(),
                        weightKg: 90,
                        repetition: .init(value: 8),
                        isDone: true
                    ),
                    SessionSetSnapshot(
                        originalSetID: UUID(),
                        weightKg: 90,
                        repetition: .init(value: 8),
                        isDone: true
                    )
                ],
                notes: "Rücken brennt angenehm"
            )
        ]

        let pullSession = WorkoutSession(
            startedAt: calendar.date(byAdding: .day, value: -5, to: now) ?? now,
            endedAt: calendar.date(byAdding: .day, value: -5, to: now) ?? now,
            maxWeightPerExercise: [
                pullSessionExercises[0].originalExerciseID: 90
            ],
            exercises: pullSessionExercises
        )

        pull.sessions = [pullSession]

        // MARK: - Körpergewicht-Beispieldaten

        let bodyweights: [BodyweightEntry] = (0..<6).map { index in
            let date = calendar.date(byAdding: .day, value: -index * 7, to: now) ?? now
            let weight = 82.0 - Double(index) * 0.5
            return BodyweightEntry(date: date, weightKg: weight)
        }

        // Reihenfolge: neueste Einträge zuerst
        store.bodyweightEntries = bodyweights.sorted { $0.date > $1.date }

        // Trainings in den Store schreiben (Push zuerst, dann Pull)
        store.trainings = [push, pull]

        return store
    }
}
#endif
