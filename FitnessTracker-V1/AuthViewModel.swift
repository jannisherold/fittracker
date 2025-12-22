import Foundation
import AuthenticationServices

@MainActor
final class AuthViewModel: ObservableObject {
    private(set) var currentNonce: String?

    struct AppleProfile {
        let email: String
        let name: String
    }

    func handleSignInWithAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = AppleSignInNonce.randomNonceString()
        currentNonce = nonce

        request.requestedScopes = [.fullName, .email]
        request.nonce = AppleSignInNonce.sha256(nonce)
    }

    /// ✅ SignIn + gibt (wenn vorhanden) Email/Name zurück (Apple liefert diese u.U. nur beim ersten Mal).
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
        // Fallbacks:
        let email = credential.email ?? authManager.userEmail

        let given = credential.fullName?.givenName ?? ""
        let family = credential.fullName?.familyName ?? ""
        let fullName = ([given, family].filter { !$0.isEmpty }).joined(separator: " ").trimmingCharacters(in: .whitespaces)

        let name = fullName.isEmpty ? "User" : fullName

        currentNonce = nil
        return AppleProfile(email: email, name: name)
    }
}
