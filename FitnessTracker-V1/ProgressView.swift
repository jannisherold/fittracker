import SwiftUI

/// Einstieg in den Progress-Tab:
/// Zeigt alle Workouts an. Tippt man eines an, geht es zur Trainings-Progress-Ansicht.
struct ProgressView: View {
    @EnvironmentObject var store: Store
    @EnvironmentObject private var purchases: PurchaseManager

    @State private var showInfo = false
    @State private var showPaywall = false

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
                    if purchases.isPremium {
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
                    } else {
                        lockedRow(title: "Kraft")
                    }
                } header: {
                    CollapsibleSectionHeader(
                        title: "Kraft",
                        iconName: "dumbbell.fill",
                        isExpanded: $isKraftExpanded
                    )
                }

                // MARK: - Statistik
                Section(isExpanded: $isStatisticExpanded) {
                    if purchases.isPremium {
                        NavigationLink {
                            ProgressStatisticView()
                        } label: {
                            Text("Rekorde anzeigen")
                                .font(.headline)
                                .padding(.vertical, 2)
                        }
                    } else {
                        lockedRow(title: "Statistik")
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
                    if purchases.isPremium {
                        NavigationLink {
                            ProgressBodyweightView()
                        } label: {
                            Text("Logbuch anzeigen")
                                .font(.headline)
                                .padding(.vertical, 2)
                        }
                    } else {
                        lockedRow(title: "Körpergewicht")
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
                    if purchases.isPremium {
                        NavigationLink {
                            ProgressFrequencyView()
                        } label: {
                            Text("Frequenz anzeigen")
                                .font(.headline)
                                .padding(.vertical, 2)
                        }
                    } else {
                        lockedRow(title: "Trainingsfrequenz")
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
                    if purchases.isPremium {
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
                                        Image(systemName: "ellipsis")
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.vertical, 8)
                                }
                            }
                        }
                    } else {
                        lockedRow(title: "Trainingshistorie")
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
            .navigationTitle("Progress+")
            .listStyle(.insetGrouped)
            .listSectionSpacing(.compact)
            .sheet(isPresented: $showPaywall) {
                PaywallView()
                    .environmentObject(purchases)
            }
        }
    }

    // MARK: - Locked row helper

    @ViewBuilder
    private func lockedRow(title: String) -> some View {
        Button {
            showPaywall = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "lock.fill")
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(title) ist Premium")
                        .font(.headline)

                    Text("Mit Progress+ freischalten")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text("Upgrade")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.blue)
            }
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
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
                    .frame(width: 28, alignment: .leading)
                    .foregroundStyle(.blue)
            }

            Text(title)
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(.primary)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
                .rotationEffect(.degrees(isExpanded ? 90 : 0))
                .animation(.easeInOut(duration: 0.2), value: isExpanded)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut) {
                isExpanded.toggle()
            }
        }
        .padding(.vertical, 4)
    }
}
