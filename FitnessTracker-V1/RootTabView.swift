import SwiftUI

enum AppTab: Hashable {
    case workout, progress, settings
}

struct RootTabView: View {
    @State private var selection: AppTab = .workout
    @EnvironmentObject var store: Store

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
        .toolbarBackground(.visible, for: .tabBar)
        .toolbar(.visible, for: .tabBar)
        .tabBarMinimizeBehavior(.onScrollDown)
    }
}

#Preview {
    RootTabView()
        .environmentObject(Store())
}
