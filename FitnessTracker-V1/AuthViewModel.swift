import Foundation
import AuthenticationServices

@MainActor
final class AuthViewModel: ObservableObject {
    private(set) var currentNonce: String?

    func handleSignInWithAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = AppleSignInNonce.randomNonceString()
        currentNonce = nonce

        request.requestedScopes = [.fullName, .email]
        request.nonce = AppleSignInNonce.sha256(nonce)
    }

    func handleSignInWithAppleCompletion(
        _ result: Result<ASAuthorization, Error>,
        authManager: SupabaseAuthManager
    ) async throws {
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

        // optional reset
        currentNonce = nil
    }
}
