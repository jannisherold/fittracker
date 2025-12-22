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
        do { try await client.auth.signOut() } catch { }
        session = nil
    }

    // MARK: - Apple Sign In

    func signInWithApple(idToken: String, nonce: String) async throws {
        let session = try await client.auth.signInWithIdToken(
            credentials: .init(provider: .apple, idToken: idToken, nonce: nonce)
        )
        self.session = session
    }

    // MARK: - Profile (Supabase DB optional) + Local AppStorage handled in UI

    /// Optional: Speichert Profil-Daten in einer `profiles` Tabelle (wenn vorhanden).
    /// Wenn Tabelle/Policies noch nicht existieren, wird der Fehler geschluckt (MVP-friendly).
    func upsertProfile(email: String, name: String, goal: String) async {
        struct ProfileRow: Encodable {
            let id: String
            let email: String
            let name: String
            let goal: String
            let updated_at: String
        }

        guard let userId = session?.user.id.uuidString else { return }

        let row = ProfileRow(
            id: userId,
            email: email,
            name: name,
            goal: goal,
            updated_at: ISO8601DateFormatter().string(from: Date())
        )

        do {
            _ = try await client
                .from("profiles")
                .upsert(row, onConflict: "id")
                .execute()
        } catch {
            // MVP: Wenn die Tabelle/Policies noch nicht da sind, blockiert das nicht den Login.
        }
    }

    // MARK: - Delete Account (Client-side via GoTrue endpoint)

    /// Löscht den aktuell eingeloggten User via GoTrue `DELETE /auth/v1/user`.
    /// Danach ist die Session weg (signOut + session=nil).
    func deleteCurrentUser() async throws {
        guard let accessToken = session?.accessToken else {
            throw NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Keine Session vorhanden"])
        }

        let url = SupabaseConfig.url.appendingPathComponent("auth/v1/user")
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw NSError(domain: "Auth", code: -2, userInfo: [NSLocalizedDescriptionKey: "Account konnte nicht gelöscht werden"])
        }

        // Lokal aufräumen
        await signOut()
    }
}
