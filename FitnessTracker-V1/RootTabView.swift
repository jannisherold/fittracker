import SwiftUI

enum AppTab: Hashable {
    case workout, progress, settings
}

struct RootTabView: View {
    @State private var selection: AppTab = .workout
    @StateObject private var store = Store()           // globaler Store
    // Hinweis: ContentView hat eigenen Router als @StateObject → bleibt lokal pro Tab erhalten

    var body: some View {
        TabView(selection: $selection) {
            // 1) WORKOUT
            WorkoutView()
                .environmentObject(store)
                .tabItem {
                    Label("Workouts", systemImage: "dumbbell")
                }
                .tag(AppTab.workout)

            // 2) PROGRESS
            ProgressView()
                .environmentObject(store)
                .tabItem {
                    Label("Progress", systemImage: "chart.bar")
                }
                .tag(AppTab.progress)

            // 3) SETTINGS
            SettingsView()
                .environmentObject(store)
                .tabItem {
                    Label("Einstellungen", systemImage: "gearshape")
                }
                .tag(AppTab.settings)
        }
        // Optional: Klare visuelle Trennung gem. HIG, aber Standard reicht meist
        .toolbarBackground(.visible, for: .tabBar)
        .toolbar(.visible, for: .tabBar)
        // A11y: klare, kurze Bezeichnungen sind wichtig – hast du über Label()
    }
}
