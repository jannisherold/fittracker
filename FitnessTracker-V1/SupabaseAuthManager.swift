import Foundation
import Supabase

@MainActor
final class SupabaseAuthManager: ObservableObject {
    @Published private(set) var session: Session?

    private let client = SupabaseManager.shared.client
    private var authListenerTask: Task<Void, Never>?

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
        startAuthListener()
    }

    deinit {
        authListenerTask?.cancel()
    }

    // MARK: - Auth Listener (offline-stabil)

    private func startAuthListener() {
        authListenerTask?.cancel()
        authListenerTask = Task { [weak self] in
            guard let self else { return }
            print("🔐 AuthListener started")

            // Wichtig: initialSession wird (mit emitLocalSessionAsInitialSession) auch offline emittiert.
            for await (event, session) in await client.auth.authStateChanges {
                print("🔐 authStateChanges event=\(event) session=\(session != nil)")

                self.session = session

                // Nach (re)login oder token refresh: Profil best-effort aus DB in lokale Defaults ziehen.
                if session != nil {
                    await self.syncProfileFromBackendToLocal()
                }
            }
        }
    }

    /// Für bestehende Call-Sites im Projekt: triggert nur noch einen best-effort Session Read.
    /// (Die eigentliche Quelle ist der Listener.)
    func restoreSession() async {
        do {
            let current = try await client.auth.session
            print("🔐 restoreSession: got session from storage (offline ok)")
            session = current
            await syncProfileFromBackendToLocal()
        } catch {
            // Wichtig: bei Offline/Keychain-Glitches NICHT aggressiv local wipe triggern.
            // Session bleibt dann einfach unverändert.
            print("⚠️ restoreSession failed (ignored): \(error)")
        }
    }

    // MARK: - Sign out

    /// Logout: Session beenden UND lokale Profile-Daten löschen (Backend bleibt)
    func signOut() async {
        print("🚪 signOut requested")
        do {
            try await client.auth.signOut()
            print("🚪 signOut: supabase signOut ok")
        } catch {
            print("⚠️ signOut: supabase signOut failed (continuing): \(error)")
        }

        session = nil
        clearLocalProfile()
        SyncStateStore.reset()
        print("🚪 signOut: local profile + sync state cleared")
    }

    // MARK: - Apple Sign In

    func signInWithApple(idToken: String, nonce: String) async throws {
        print(" Sign in with Apple...")
        let newSession = try await client.auth.signInWithIdToken(
            credentials: .init(provider: .apple, idToken: idToken, nonce: nonce)
        )
        self.session = newSession
        print(" Sign in with Apple OK. userId=\(newSession.user.id)")

        // Nach Login: Profil aus DB holen und lokal speichern
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
        guard let userId = session?.user.id.uuidString else {
            print("⚠️ upsertProfile: no session")
            return
        }

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

        print("👤 upsertProfile: \(userId) goal=\(goal)")
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

            let fallbackGoal = UserDefaults.standard.string(forKey: Keys.onboardingGoal) ?? "Überspringen"
            setLocalProfile(
                email: profile.email ?? userEmail,
                name: profile.name ?? "User",
                goal: profile.goal ?? fallbackGoal
            )

            print("👤 syncProfileFromBackendToLocal OK name=\(profile.name ?? "nil") goal=\(profile.goal ?? "nil")")
        } catch {
            // Wenn noch kein Profil existiert, lassen wir lokal erstmal wie es ist.
            print("⚠️ syncProfileFromBackendToLocal failed (ignored): \(error)")
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

    /// Löscht: 1) user_data row 2) profile row 3) Auth-User 4) lokal alles
    func deleteAccountCompletely() async throws {
        guard let userId = session?.user.id.uuidString else {
            throw NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Kein User eingeloggt"])
        }

        print("🗑️ deleteAccountCompletely userId=\(userId)")

        // 1) user_data row löschen
        do {
            _ = try await client
                .from("user_data")
                .delete()
                .eq("user_id", value: userId)
                .execute()
            print("🗑️ deleteAccountCompletely: user_data deleted")
        } catch {
            print("⚠️ deleteAccountCompletely: user_data delete failed (continuing): \(error)")
        }

        // 2) profile row löschen
        do {
            _ = try await client
                .from("profiles")
                .delete()
                .eq("id", value: userId)
                .execute()
            print("🗑️ deleteAccountCompletely: profile deleted")
        } catch {
            print("⚠️ deleteAccountCompletely: profile delete failed (continuing): \(error)")
        }

        // 3) Auth-User löschen (GoTrue Endpoint)
        try await deleteCurrentUserViaGoTrue()
        print("🗑️ deleteAccountCompletely: auth user deleted")

        // 4) Lokal alles
        clearLocalProfile()
        SyncStateStore.reset()
        session = nil
    }

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
