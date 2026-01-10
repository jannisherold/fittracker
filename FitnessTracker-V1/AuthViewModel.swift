import Foundation
import AuthenticationServices

@MainActor
final class AuthViewModel: ObservableObject {
    private(set) var currentNonce: String?

    struct AppleProfile {
        let email: String
        let firstName: String
        let lastName: String
    }

    func handleSignInWithAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = AppleSignInNonce.randomNonceString()
        currentNonce = nonce

        request.requestedScopes = [.fullName, .email]
        request.nonce = AppleSignInNonce.sha256(nonce)
    }

    /// SignIn + gibt (wenn vorhanden) Email/Vorname/Nachname zurück (Apple liefert fullName oft nur beim ersten Mal).
    func handleSignInWithAppleCompletionAndReturnProfile(
        _ result: Result<ASAuthorization, Error>,
        authManager: SupabaseAuthManager
    ) async throws -> AppleProfile {
        let authorization = try result.get()

        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            throw NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Kein Apple Credential"])
        }

        guard let nonce = currentNonce else {
            throw NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Nonce fehlt"])
        }

        guard let tokenData = credential.identityToken,
              let idToken = String(data: tokenData, encoding: .utf8) else {
            throw NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Identity Token fehlt"])
        }

        // ✅ Supabase Login
        try await authManager.signInWithApple(idToken: idToken, nonce: nonce)

        // Email/Name: kann nil sein (Apple gibt es nicht immer zurück).
        let email = credential.email ?? authManager.userEmail
        let first = (credential.fullName?.givenName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let last  = (credential.fullName?.familyName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

        currentNonce = nil
        return AppleProfile(email: email, firstName: first, lastName: last)
    }
}
