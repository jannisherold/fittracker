import Foundation
import Supabase

@MainActor
final class SupabaseAuthManager: ObservableObject {
    @Published private(set) var session: Session?

    private let client = SupabaseManager.shared.client

    var isLoggedIn: Bool { session != nil }
    var userEmail: String { session?.user.email ?? "" }

    init() {
        Task { await restoreSession() }
    }

    func restoreSession() async {
        do { session = try await client.auth.session }
        catch { session = nil }
    }

    func signOut() async {
        try? await client.auth.signOut()
        session = nil
    }

    // ✅ Apple
    func signInWithApple(idToken: String, nonce: String) async throws {
        let session = try await client.auth.signInWithIdToken(
            credentials: .init(provider: .apple, idToken: idToken, nonce: nonce)
        )
        self.session = session
    }

    // ✅ (ALT) Klassisches Email+Passwort SignUp (Link-Confirm möglich)
    func signUpWithEmail(email: String, password: String) async throws {
        _ = try await client.auth.signUp(email: email, password: password)
        await restoreSession()
    }

    func signInWithEmail(email: String, password: String) async throws {
        let session = try await client.auth.signIn(email: email, password: password)
        self.session = session
    }

    // ✅ NEU: OTP an Email senden (6-stelliger Code / oder magic link – je nach Supabase Setting)
    // ✅ OTP an Email senden (6-stelliger Code / oder Magic Link – je nach Template)
    func sendEmailOTP(email: String) async throws {
        // Wichtig: In Swift SDK wird shouldCreateUser als eigener Parameter übergeben, nicht über options:
        try await client.auth.signInWithOTP(
            email: email,
            shouldCreateUser: true
        )
    }

    // ✅ OTP verifizieren -> erzeugt AuthResponse (nicht Session), daher session daraus holen
    func verifyEmailOTP(email: String, code: String) async throws {
        let response = try await client.auth.verifyOTP(
            email: email,
            token: code,
            // Je nach dem, was du vorher aufgerufen hast:
            // - Für "signInWithOTP(...)" ist .signup häufig korrekt, wenn dabei User angelegt wird
            type: .signup
        )

        // Deine Fehlermeldung kam, weil response != Session
        self.session = response.session

        // Falls session in response nil ist (kommt je nach Setup vor), dann Session danach nochmal holen:
        if self.session == nil {
            await restoreSession()
        }
    }

    // ✅ Passwort setzen (nachdem Session existiert)
    func setPassword(_ password: String) async throws {
        try await client.auth.update(user: UserAttributes(password: password))
        await restoreSession()
    }

}
