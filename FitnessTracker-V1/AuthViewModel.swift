import SwiftUI
import AuthenticationServices

final class AuthViewModel: ObservableObject {
    /// Anonymisierte Apple-User-ID (kannst du später für iCloud / Account-Handling nutzen)
    @AppStorage("appleUserID") var appleUserID: String = ""

    /// Wird beim Request aufgerufen: hier kannst du Scopes setzen (Name, Mail etc.)
    func handleSignInWithAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.fullName, .email]
    }

    /// Wird nach dem Login aufgerufen
    func handleSignInWithAppleCompletion(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let credential = authorization.credential as? ASAuthorizationAppleIDCredential {
                // Persistiere die User-ID lokal (für späteres Account-Handling)
                appleUserID = credential.user
                print("✅ Sign in with Apple Erfolg, userID: \(credential.user)")
            }
        case .failure(let error):
            print("❌ Sign in with Apple Fehler: \(error.localizedDescription)")
        }
    }
}
