import SwiftUI

struct AddExerciseView: View {
    enum AfterSave { case dismiss, goToEdit }

    @EnvironmentObject var store: Store
    @EnvironmentObject private var router: Router

    let trainingID: UUID
    let afterSave: AfterSave

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var setCount = 3

    var body: some View {
        Form {
            Section("Name") { TextField("Übungsname", text: $name) }
            Section("Sätze") {
                Stepper(value: $setCount, in: 1...10) { Text("\(setCount) Sätze") }
            }
        }
        .scrollDismissesKeyboard(.immediately)
        .onTapGesture { hideKeyboard() }
        .navigationTitle("Übung hinzufügen")
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    // Pfeil-Verhalten abhängig davon, wie wir hier sind
                    switch afterSave {
                    case .dismiss:
                        dismiss() // Sheet -> zurück zur WorkoutEditView
                    case .goToEdit:
                        router.replaceTop(with: .workoutEdit(trainingID: trainingID)) // Push -> Edit
                    }
                } label: {
                    Image(systemName: "chevron.left")
                }
                .accessibilityLabel("Zur Workout-Bearbeitung")
            }
            
            ToolbarItem(placement: .confirmationAction) {
                Button("Speichern") {
                    let n = name.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !n.isEmpty else { return }
                    store.addExercise(to: trainingID, name: n, setCount: setCount)
                    switch afterSave {
                    case .dismiss:
                        dismiss()
                    case .goToEdit:
                        router.replaceTop(with: .workoutEdit(trainingID: trainingID))
                    }
                }
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }
}
