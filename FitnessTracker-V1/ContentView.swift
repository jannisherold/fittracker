import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: Store
    @State private var showingNew = false
    @State private var newTitle = ""

    var body: some View {
        NavigationStack {
            
            
            List {
                ForEach(store.trainings) { t in
                        // Standard: Tippen startet Workout
                        NavigationLink(t.title) {
                            WorkoutRunView(trainingID: t.id)
                        }
                        // Long-Press Menü für Bearbeiten
                        .contextMenu {
                            NavigationLink {
                                TrainingDetailView(trainingID: t.id) // deine bestehende Edit-Ansicht
                            } label: {
                                Label("Bearbeiten", systemImage: "pencil")
                            }
                        }
                    }
                    .onDelete { store.deleteTraining(at: $0) }
            }
            
            
            .navigationTitle("Workouts")
        
            
            // 👇 Toolbar AN den NavigationStack hängen – mit topBar-Placements
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingNew = true } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Neues Training")
                }
            }
        }
        .sheet(isPresented: $showingNew) {
            NavigationStack {
                Form { TextField("Titel (z. B. Oberkörper, Unterkörper, ...)", text: $newTitle) }
                    .navigationTitle("Training anlegen")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) { Button("Abbrechen") { showingNew = false } }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Speichern") {
                                let t = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                                guard !t.isEmpty else { return }
                                store.addTraining(title: t)
                                newTitle = ""
                                showingNew = false
                            }
                            .disabled(newTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
            }
            .presentationDetents([.height(220)])
        }
    }
}
