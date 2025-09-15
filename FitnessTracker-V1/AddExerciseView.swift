import SwiftUI

struct AddExerciseView: View {
    enum AfterSave { case dismiss, goToEdit }
    @EnvironmentObject var store: Store
    let trainingID: UUID
    let afterSave: AfterSave

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var setCount = 3
    @State private var goToEdit = false   // Navigation-Trigger

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") { TextField("Übungsname", text: $name) }
                Section("Sätze") {
                    Stepper(value: $setCount, in: 1...10) { Text("\(setCount) Sätze") }
                }
            }
            .navigationTitle("Übung hinzufügen")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        let n = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !n.isEmpty else { return }
                        store.addExercise(to: trainingID, name: n, setCount: setCount)
                        switch afterSave {
                        case .dismiss:   dismiss()
                        case .goToEdit:  goToEdit = true
                        }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            // versteckter Link, der nach dem Speichern pusht
            NavigationLink(isActive: $goToEdit) {
                WorkoutEditView(trainingID: trainingID).environmentObject(store)
            } label: { EmptyView() }
        }
    }
}
