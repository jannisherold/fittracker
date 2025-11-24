import SwiftUI

// Liste aller vergangenen Sessions (neueste oben, älteste unten)
struct ProgressHistoryList: View {
    @EnvironmentObject var store: Store

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
        ZStack {
            Color(.secondarySystemBackground).ignoresSafeArea()

            if sessionHistory.isEmpty {
                VStack(spacing: 12) {
                    Text("Noch keine Sessions vorhanden")
                        .font(.headline)
                    Text("Sobald du ein Workout absolviert hast, erscheint es hier.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            } else {
                List {
                    Section(header: Text("Alle Sessions")) {
                        ForEach(sessionHistory, id: \.session.id) { item in
                            NavigationLink {
                                // Zeitreise-Detailansicht mit allen Infos
                                ProgressHistoryDetailView(
                                    trainingID: item.training.id,
                                    sessionID: item.session.id
                                )
                            } label: {
                                historyRow(for: item.training, session: item.session)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Trainingshistorie")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Row-Layout (an ProgressView angelehnt)
    private func historyRow(for training: Training, session: WorkoutSession) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(training.title)
                .font(.headline)

            HStack(spacing: 2) {
                Text(session.endedAt.formatted(date: .abbreviated, time: .omitted))
                /*
                Text("•")
                Text(formatDuration(session.duration))
                 */
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Dauer formatieren (wie in ProgressHistoryDetailView)
    private func formatDuration(_ interval: TimeInterval) -> String {
        let totalMinutes = Int(interval / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if hours > 0 {
            return "\(hours) h \(minutes) min"
        } else {
            return "\(minutes) min"
        }
    }
}

#Preview {
    // Beispiel-Preview mit leerem Store – hier könntest du Testdaten einspeisen
    let store = Store()
    return NavigationStack {
        ProgressHistoryList()
            .environmentObject(store)
    }
}
