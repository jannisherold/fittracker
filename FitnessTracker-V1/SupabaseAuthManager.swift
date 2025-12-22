import Foundation
import Supabase

@MainActor
final class SupabaseAuthManager: ObservableObject {
    @Published private(set) var session: Session?

    private let client = SupabaseManager.shared.client

    var isLoggedIn: Bool { session != nil }
    var userEmail: String { session?.user.email ?? "" }

    // MARK: - Local Storage Keys (müssen zu @AppStorage Keys passen)
    private enum Keys {
        static let userEmail = "userEmail"
        static let userName  = "userName"
        static let userGoal  = "userGoal"
        static let onboardingGoal = "onboardingGoal"
    }

    init() {
        Task { await restoreSession() }
    }

    // MARK: - Session

    func restoreSession() async {
        do {
            session = try await client.auth.session
            // ✅ Wichtig: Nach Restore Profil aus DB holen und lokal speichern
            await syncProfileFromBackendToLocal()
        } catch {
            session = nil
        }
    }

    /// Logout: Session beenden UND lokale Profile-Daten löschen (Backend bleibt)
    func signOut() async {
        do { try await client.auth.signOut() } catch { }
        session = nil
        clearLocalProfile()
    }

    // MARK: - Apple Sign In

    func signInWithApple(idToken: String, nonce: String) async throws {
        let session = try await client.auth.signInWithIdToken(
            credentials: .init(provider: .apple, idToken: idToken, nonce: nonce)
        )
        self.session = session

        // ✅ Nach Login: Profil aus DB holen und lokal speichern
        await syncProfileFromBackendToLocal()
    }

    // MARK: - Profile DB

    struct ProfileRow: Codable {
        let id: String
        let email: String?
        let name: String?
        let goal: String?
        let created_at: String?
        let updated_at: String?
    }

    /// Upsert Profil in `profiles` (id = auth.user.id)
    func upsertProfile(email: String, name: String, goal: String) async throws {
        guard let userId = session?.user.id.uuidString else { return }

        struct UpsertRow: Encodable {
            let id: String
            let email: String
            let name: String
            let goal: String
            let updated_at: String
        }

        let row = UpsertRow(
            id: userId,
            email: email,
            name: name,
            goal: goal,
            updated_at: ISO8601DateFormatter().string(from: Date())
        )

        _ = try await client
            .from("profiles")
            .upsert(row, onConflict: "id")
            .execute()
    }

    /// Lädt Profil aus `profiles` und schreibt es in UserDefaults (-> @AppStorage aktualisiert sich)
    func syncProfileFromBackendToLocal() async {
        guard let userId = session?.user.id.uuidString else { return }

        do {
            let response = try await client
                .from("profiles")
                .select("id,email,name,goal,created_at,updated_at")
                .eq("id", value: userId)
                .single()
                .execute()

            let profile = try JSONDecoder().decode(ProfileRow.self, from: response.data)

            setLocalProfile(
                email: profile.email ?? userEmail,
                name: profile.name ?? "User",
                goal: profile.goal ?? (UserDefaults.standard.string(forKey: Keys.onboardingGoal) ?? "Überspringen")
            )
        } catch {
            // Wenn noch kein Profil existiert, lassen wir lokal erstmal wie es ist.
            // Optional könntest du hier auch automatisch ein Default-Profil anlegen.
        }
    }

    // MARK: - Local Profile Storage (UserDefaults)

    func setLocalProfile(email: String, name: String, goal: String) {
        UserDefaults.standard.set(email, forKey: Keys.userEmail)
        UserDefaults.standard.set(name, forKey: Keys.userName)
        UserDefaults.standard.set(goal, forKey: Keys.userGoal)
    }

    func clearLocalProfile() {
        UserDefaults.standard.removeObject(forKey: Keys.userEmail)
        UserDefaults.standard.removeObject(forKey: Keys.userName)
        UserDefaults.standard.removeObject(forKey: Keys.userGoal)
        // onboardingGoal lassen wir bewusst stehen (kommt aus Onboarding Screen)
    }

    // MARK: - Delete Account

    /// Löscht: 1) Profilrow in DB (falls vorhanden) 2) Auth-User 3) lokal alles
    func deleteAccountCompletely() async throws {
        // 1) Profilrow löschen (falls RLS erlaubt)
        if let userId = session?.user.id.uuidString {
            do {
                _ = try await client
                    .from("profiles")
                    .delete()
                    .eq("id", value: userId)
                    .execute()
            } catch {
                // Wenn FK cascade existiert, ist das optional.
                // Wenn nicht: RLS/Policy prüfen.
            }
        }

        // 2) Auth-User löschen (GoTrue Endpoint)
        try await deleteCurrentUserViaGoTrue()

        // 3) Lokal alles
        clearLocalProfile()
        session = nil
    }

    /// GoTrue `DELETE /auth/v1/user` (Self-Delete). Sollte funktionieren, solange Supabase das erlaubt.
    /// GoTrue `DELETE /auth/v1/user` (Self-Delete).
    /// GoTrue `DELETE /auth/v1/user` (Self-Delete).
    private func deleteCurrentUserViaGoTrue() async throws {
        // Frische Session holen (Token kann sich ändern)
        let currentSession = try await client.auth.session

        let url = SupabaseConfig.url.appendingPathComponent("auth/v1/user")
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(currentSession.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw NSError(domain: "Auth", code: -2, userInfo: [NSLocalizedDescriptionKey: "Ungültige Server-Antwort"])
        }

        if !(200...299).contains(http.statusCode) {
            let body = String(data: data, encoding: .utf8) ?? "<kein Body>"
            throw NSError(
                domain: "Auth",
                code: http.statusCode,
                userInfo: [NSLocalizedDescriptionKey: "Auth-Delete fehlgeschlagen (HTTP \(http.statusCode)): \(body)"]
            )
        }
    }


}
