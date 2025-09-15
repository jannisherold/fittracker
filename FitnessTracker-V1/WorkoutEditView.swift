import SwiftUI

struct WorkoutEditView: View {
    @EnvironmentObject var store: Store
    let trainingID: UUID

    @State private var showingNewExercise = false
    @Environment(\.editMode) private var editMode     // ← für eigenen Edit-Schalter

    private var training: Training? {
        store.trainings.first(where: { $0.id == trainingID })
    }

    var body: some View {
        List {
            if let training {
                Section("ÜBUNGEN") {
                    ForEach(training.exercises) { ex in
                        NavigationLink(ex.name) {
                            ExerciseDetailView(trainingID: trainingID, exerciseID: ex.id)
                        }
                    }
                    .onDelete { offsets in
                        store.deleteExercise(in: trainingID, at: offsets)
                    }
                }
            }
        }
        .navigationTitle(training?.title ?? "Training")
        .navigationBarTitleDisplayMode(.large)
        // 🔽 Leiste direkt unter dem großen Titel
        .safeAreaInset(edge: .top) { headerControls }
        // (Keine Toolbar mehr für Edit/+)
        
        .sheet(isPresented: $showingNewExercise) {
            AddExerciseView(trainingID: trainingID, afterSave: .dismiss)
                .environmentObject(store)
        }
        
    }

    // MARK: - Header unter Titel
    private var headerControls: some View {
        HStack {
            Button {
                // Toggle Edit-Modus der List
                withAnimation {
                    if editMode?.wrappedValue == .active {
                        editMode?.wrappedValue = .inactive
                    } else {
                        editMode?.wrappedValue = .active
                    }
                }
            } label: {
                Label(editMode?.wrappedValue == .active ? "Fertig" : "Übungen bearbeiten",
                      systemImage: "pencil")
            }

            Spacer()

            Button {
                showingNewExercise = true
            } label: {
                Label("Übung", systemImage: "plus")
                    .fontWeight(.semibold)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
        //.background(.ultraThinMaterial)   // dezente Fläche unter dem Titel
        //.shadow(radius: 0.5)
    }

}
