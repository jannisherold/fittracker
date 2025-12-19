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

}
