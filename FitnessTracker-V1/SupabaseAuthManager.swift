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

    /// ✅ Native Apple Sign-In Token → Supabase Session
    func signInWithApple(idToken: String, nonce: String) async throws {
        let session = try await client.auth.signInWithIdToken(
            credentials: .init(
                provider: .apple,
                idToken: idToken,
                nonce: nonce
            )
        )
        self.session = session
    }

    // MARK: - ✅ Email + Passwort

    /// ✅ Sign Up mit Email + Passwort
    func signUpWithEmail(email: String, password: String) async throws {
        // Supabase liefert je nach Email-Confirm Setting ggf. nicht sofort eine Session.
        // In vielen Setups bekommst du aber direkt eine Session.
        _ = try await client.auth.signUp(email: email, password: password)

        // Session danach sauber neu holen (funktioniert auch, wenn Supabase direkt eine Session gesetzt hat)
        await restoreSession()
    }

    /// ✅ Sign In mit Email + Passwort (für später / Login-View)
    func signInWithEmail(email: String, password: String) async throws {
        let session = try await client.auth.signIn(email: email, password: password)
        self.session = session
    }
}
