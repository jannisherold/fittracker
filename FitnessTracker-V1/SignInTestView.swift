import SwiftUI
import AuthenticationServices

struct SignInTestView: View {
    @StateObject private var authViewModel = AuthViewModel()

    var body: some View {
        VStack(spacing: 20) {
            Text("Sign in with Apple Test")
                .font(.title2)
                .padding()

            SignInWithAppleButton(.signIn,
                                  onRequest: authViewModel.handleSignInWithAppleRequest,
                                  onCompletion: { result in
                switch result {
                case .success(let authorization):
                    print("✅ Erfolg: \(authorization)")
                case .failure(let error):
                    print("❌ Fehler: \(error.localizedDescription)")
                }
            })
            .signInWithAppleButtonStyle(.black)
            .frame(height: 50)
            .padding()
        }
    }
}
