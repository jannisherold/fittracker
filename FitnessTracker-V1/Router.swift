import SwiftUI

enum Route: Hashable {
    case workoutInspect(trainingID: UUID)      // NEU: Zwischenansicht
    case workoutRun(trainingID: UUID)
    case workoutEdit(trainingID: UUID)
    case exerciseEdit(trainingID: UUID, exerciseID: UUID)
    case addExercise(trainingID: UUID)
}

final class Router: ObservableObject {
    @Published var path = NavigationPath()

    func popToRoot() {
        path.removeLast(path.count)
    }

    func go(_ route: Route) {
        path.append(route)
    }

    /// Ersetzt die oberste Route (falls vorhanden) durch eine neue
    func replaceTop(with route: Route) {
        if path.count > 0 { path.removeLast() }
        path.append(route)
    }

    /// Setzt den Stack auf genau diese Reihenfolge (z. B. direkt zu Run)
    func setRoot(_ routes: [Route]) {
        path = NavigationPath()
        for r in routes { path.append(r) }
    }
}
