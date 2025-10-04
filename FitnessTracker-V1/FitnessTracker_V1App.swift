import SwiftUI

import FirebaseCore


class AppDelegate: NSObject, UIApplicationDelegate {

  func application(_ application: UIApplication,

                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {

    FirebaseApp.configure()

    return true

  }

}


@main
struct FitnessTrackerV1App: App {
    // register app delegate for Firebase setup

    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    @StateObject private var store = Store()

    var body: some Scene {
        WindowGroup {
            SplashScreenView()
                .environmentObject(store)
        }
    }
}
