import SwiftUI

struct ProgressView: View {
    @EnvironmentObject var store: Store

    var body: some View {
        NavigationStack {
            List {
                // Beispiel: einfache Zusammenfassung deiner Trainings
                ForEach(store.trainings) { t in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(t.title).font(.headline)
                        Text(t.date.formatted(date: .abbreviated, time: .omitted))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Progress")
        }
    }
}
