import SwiftUI

import FirebaseCore
import FirebaseAuth


class AppDelegate: NSObject, UIApplicationDelegate {

  func application(_ application: UIApplication,

                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {

    FirebaseApp.configure()

    return true

  }

}


@main
struct FitnessTrackerV1App: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var store = Store()
    @StateObject private var authVM = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            SplashScreenView()
                .environmentObject(store)
                .environmentObject(authVM)
        }
    }
}
