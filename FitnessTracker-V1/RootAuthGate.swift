import SwiftUI

struct RootAuthGate: View {
  @EnvironmentObject var auth: AuthViewModel

  var body: some View {
    Group {
      if auth.isAuthenticated {
        RootTabView()      // deine Tabs
      } else {
        AuthView()
      }
    }
    .onAppear { auth.refresh() }
  }
}
