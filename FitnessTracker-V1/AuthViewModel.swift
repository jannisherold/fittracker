import SwiftUI
import AuthenticationServices

final class AuthViewModel: ObservableObject {
    @AppStorage("appleUserID") var appleUserID: String = ""

    // 🔽 neu:
    @AppStorage("appleFirstName") var appleFirstName: String = ""
    @AppStorage("appleLastName") var appleLastName: String = ""
    @AppStorage("appleEmail") var appleEmail: String = ""

    func handleSignInWithAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.fullName, .email]
    }

    func handleSignInWithAppleCompletion(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let credential = authorization.credential as? ASAuthorizationAppleIDCredential {
                // User-ID immer speichern
                appleUserID = credential.user
                print("✅ Sign in with Apple Erfolg, userID: \(credential.user)")

                // ⚠️ Name & E-Mail liefert Apple nur beim ersten Login!
                if let fullName = credential.fullName {
                    if let givenName = fullName.givenName, !givenName.isEmpty {
                        appleFirstName = givenName
                    }
                    if let familyName = fullName.familyName, !familyName.isEmpty {
                        appleLastName = familyName
                    }
                }

                if let email = credential.email, !email.isEmpty {
                    appleEmail = email
                }
            }
        case .failure(let error):
            print("❌ Sign in with Apple Fehler: \(error.localizedDescription)")
        }
    }
}
