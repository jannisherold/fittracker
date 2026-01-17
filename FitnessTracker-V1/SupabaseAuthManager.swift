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
        static let userFirstName = "userFirstName"
        static let userLastName  = "userLastName"
        static let userGoal  = "userGoal"
        static let userContactEmail = "userContactEmail"
        static let userMarketingOptIn = "userMarketingOptIn"
        static let onboardingGoal = "onboardingGoal"

        // Registration Gate
        static let hasFinalizedRegistration = "hasFinalizedRegistration"

        // Pending Registration (nach SIWA, vor Finalize Screen)
        static let pendingFirstName = "pendingFirstName"
        static let pendingLastName = "pendingLastName"
        static let pendingContactEmail = "pendingContactEmail"

        // Legacy (alte Builds)
        static let userNameLegacy  = "userName"
    }

    init() {
        migrateLegacyNameIfNeeded()
        startAuthListener()
    }

    deinit { authListenerTask?.cancel() }

    // MARK: - Auth Listener (offline-stabil)
    private func startAuthListener() {
        authListenerTask?.cancel()
        authListenerTask = Task { [weak self] in
            guard let self else { return }
            print("🔐 AuthListener started")

            for await (event, newSession) in await client.auth.authStateChanges {
                print("🔐 authStateChanges event=\(event) session=\(newSession != nil)")
                self.session = newSession

                if newSession != nil {
                    await self.syncProfileFromBackendToLocal()
                }
            }
        }
    }

    func restoreSession() async {
        do {
            let current = try await client.auth.session
            print("🔐 restoreSession: got session from storage (offline ok)")
            session = current
            await syncProfileFromBackendToLocal()
        } catch {
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
        clearRegistrationGate()
        SyncStateStore.reset()
        print("🚪 signOut: local profile + sync state cleared")
    }

    private func clearRegistrationGate() {
        UserDefaults.standard.set(false, forKey: Keys.hasFinalizedRegistration)
        UserDefaults.standard.removeObject(forKey: Keys.pendingFirstName)
        UserDefaults.standard.removeObject(forKey: Keys.pendingLastName)
        UserDefaults.standard.removeObject(forKey: Keys.pendingContactEmail)
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
        let contact_email: String?
        let first_name: String?
        let last_name: String?
        let name: String? // optional legacy/compat
        let goal: String?
        let marketing_opt_in: Bool?
        let marketing_opt_in_at: String?
        let terms_accepted_at: String?
        let privacy_accepted_at: String?
        let created_at: String?
        let updated_at: String?
    }

    /// Upsert Profil in `profiles` (id = auth.user.id)
    func upsertProfile(email: String, firstName: String, lastName: String, goal: String) async throws {
        guard let userId = session?.user.id.uuidString else {
            print("⚠️ upsertProfile: no session")
            return
        }

        let fn = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let ln = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        let fullName = ([fn, ln].filter { !$0.isEmpty }).joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)

        struct UpsertRow: Encodable {
            let id: String
            let email: String
            let first_name: String
            let last_name: String
            let name: String
            let goal: String
            let updated_at: String
        }

        let row = UpsertRow(
            id: userId,
            email: email,
            first_name: fn,
            last_name: ln,
            name: fullName, // optional, hält alte Tools/Views lesbar
            goal: goal,
            updated_at: ISO8601DateFormatter().string(from: Date())
        )

        print("👤 upsertProfile: \(userId) first=\(fn) last=\(ln) goal=\(goal)")
        _ = try await client
            .from("profiles")
            .upsert(row, onConflict: "id")
            .execute()
    }

    /// Finaler Registrierungsschritt (Variante 1):
    /// - schreibt Profil + Consent-Felder in `profiles`
    /// - setzt danach lokal `hasFinalizedRegistration = true`
    ///
    /// ⚠️ Voraussetzung: In deiner Supabase-Tabelle `profiles` müssen folgende Spalten existieren:
    /// `contact_email`, `marketing_opt_in`, `marketing_opt_in_at`, `terms_accepted_at`, `privacy_accepted_at`.
    func finalizeRegistration(
        contactEmail: String,
        firstName: String,
        lastName: String,
        goal: String,
        marketingOptIn: Bool
    ) async throws {
        guard let userId = session?.user.id.uuidString else {
            throw NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Kein User eingeloggt"])
        }

        let fn = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let ln = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        let fullName = ([fn, ln].filter { !$0.isEmpty }).joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        let now = ISO8601DateFormatter().string(from: Date())

        struct UpsertRow: Encodable {
            let id: String
            let email: String
            let contact_email: String
            let first_name: String
            let last_name: String
            let name: String
            let goal: String
            let marketing_opt_in: Bool
            let marketing_opt_in_at: String?
            let terms_accepted_at: String
            let privacy_accepted_at: String
            let updated_at: String
        }

        let row = UpsertRow(
            id: userId,
            email: userEmail,
            contact_email: contactEmail,
            first_name: fn,
            last_name: ln,
            name: fullName,
            goal: goal,
            marketing_opt_in: marketingOptIn,
            marketing_opt_in_at: marketingOptIn ? now : nil,
            terms_accepted_at: now,
            privacy_accepted_at: now,
            updated_at: now
        )

        print("✅ finalizeRegistration: upsert profile+consents userId=\(userId) marketing=\(marketingOptIn)")
        _ = try await client
            .from("profiles")
            .upsert(row, onConflict: "id")
            .execute()

        // Backend -> Lokal
        await syncProfileFromBackendToLocal()

        // Gate öffnen
        UserDefaults.standard.set(true, forKey: Keys.hasFinalizedRegistration)

        // Pending Felder leeren
        UserDefaults.standard.removeObject(forKey: Keys.pendingFirstName)
        UserDefaults.standard.removeObject(forKey: Keys.pendingLastName)
        UserDefaults.standard.removeObject(forKey: Keys.pendingContactEmail)
    }

    /// Lädt Profil aus `profiles` und schreibt es in UserDefaults (-> @AppStorage aktualisiert sich)
    func syncProfileFromBackendToLocal() async {
        guard let userId = session?.user.id.uuidString else { return }

        do {
            // 1) Neuer Schema-Select (inkl. Consent-Felder)
            let response = try await client
                .from("profiles")
                .select("id,email,contact_email,first_name,last_name,name,goal,marketing_opt_in,marketing_opt_in_at,terms_accepted_at,privacy_accepted_at,created_at,updated_at")
                .eq("id", value: userId)
                .single()
                .execute()

            let profile = try JSONDecoder().decode(ProfileRow.self, from: response.data)

            let fallbackGoal = UserDefaults.standard.string(forKey: Keys.onboardingGoal) ?? "Überspringen"
            let (fallbackFirst, fallbackLast) = splitNameFallback(profile.name)

            let first = (profile.first_name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let last  = (profile.last_name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

            let resolvedFirst = first.isEmpty ? fallbackFirst : first
            let resolvedLast  = last.isEmpty ? fallbackLast : last

            setLocalProfile(
                email: profile.email ?? userEmail,
                firstName: resolvedFirst,
                lastName: resolvedLast,
                goal: profile.goal ?? fallbackGoal,
                contactEmail: (profile.contact_email ?? "").trimmingCharacters(in: .whitespacesAndNewlines),
                marketingOptIn: profile.marketing_opt_in ?? false
            )

            // Registrierung gilt als final, wenn Consent gesetzt ist.
            let finalized = (profile.terms_accepted_at ?? "").isEmpty == false
            UserDefaults.standard.set(finalized, forKey: Keys.hasFinalizedRegistration)

            print("👤 syncProfileFromBackendToLocal OK first=\(resolvedFirst) last=\(resolvedLast) goal=\(profile.goal ?? "nil")")
        } catch {
            // 2) Fallback: älteres Schema (falls Spalten noch nicht angelegt sind)
            do {
                let response = try await client
                    .from("profiles")
                    .select("id,email,first_name,last_name,name,goal,created_at,updated_at")
                    .eq("id", value: userId)
                    .single()
                    .execute()

                let profile = try JSONDecoder().decode(ProfileRow.self, from: response.data)

                let fallbackGoal = UserDefaults.standard.string(forKey: Keys.onboardingGoal) ?? "Überspringen"
                let (fallbackFirst, fallbackLast) = splitNameFallback(profile.name)

                let first = (profile.first_name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                let last  = (profile.last_name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

                let resolvedFirst = first.isEmpty ? fallbackFirst : first
                let resolvedLast  = last.isEmpty ? fallbackLast : last

                setLocalProfile(
                    email: profile.email ?? userEmail,
                    firstName: resolvedFirst,
                    lastName: resolvedLast,
                    goal: profile.goal ?? fallbackGoal,
                    contactEmail: (profile.contact_email ?? "").trimmingCharacters(in: .whitespacesAndNewlines),
                    marketingOptIn: profile.marketing_opt_in ?? false
                )

                // Legacy-Profil ohne Consent-Felder: wir lassen den Nutzer wie bisher rein.
                UserDefaults.standard.set(true, forKey: Keys.hasFinalizedRegistration)

                print("👤 syncProfileFromBackendToLocal (legacy) OK first=\(resolvedFirst) last=\(resolvedLast)")
            } catch {
                print("⚠️ syncProfileFromBackendToLocal failed (ignored): \(error)")
            }
        }
    }

    // MARK: - Local Profile Storage (UserDefaults)

    func setLocalProfile(
        email: String,
        firstName: String,
        lastName: String,
        goal: String,
        contactEmail: String = "",
        marketingOptIn: Bool = false
    ) {
        UserDefaults.standard.set(email, forKey: Keys.userEmail)
        UserDefaults.standard.set(firstName, forKey: Keys.userFirstName)
        UserDefaults.standard.set(lastName, forKey: Keys.userLastName)
        UserDefaults.standard.set(goal, forKey: Keys.userGoal)
        UserDefaults.standard.set(contactEmail, forKey: Keys.userContactEmail)
        UserDefaults.standard.set(marketingOptIn, forKey: Keys.userMarketingOptIn)
    }

    func clearLocalProfile() {
        UserDefaults.standard.removeObject(forKey: Keys.userEmail)
        UserDefaults.standard.removeObject(forKey: Keys.userFirstName)
        UserDefaults.standard.removeObject(forKey: Keys.userLastName)
        UserDefaults.standard.removeObject(forKey: Keys.userGoal)
        UserDefaults.standard.removeObject(forKey: Keys.userContactEmail)
        UserDefaults.standard.removeObject(forKey: Keys.userMarketingOptIn)
        UserDefaults.standard.removeObject(forKey: Keys.userNameLegacy)
        UserDefaults.standard.set(false, forKey: Keys.hasFinalizedRegistration)
        UserDefaults.standard.removeObject(forKey: Keys.pendingFirstName)
        UserDefaults.standard.removeObject(forKey: Keys.pendingLastName)
        UserDefaults.standard.removeObject(forKey: Keys.pendingContactEmail)
        // onboardingGoal lassen wir bewusst stehen
    }

    private func migrateLegacyNameIfNeeded() {
        let first = UserDefaults.standard.string(forKey: Keys.userFirstName) ?? ""
        let last  = UserDefaults.standard.string(forKey: Keys.userLastName) ?? ""
        guard first.isEmpty && last.isEmpty else { return }

        let legacy = UserDefaults.standard.string(forKey: Keys.userNameLegacy) ?? ""
        guard !legacy.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        let (f, l) = splitNameFallback(legacy)
        UserDefaults.standard.set(f, forKey: Keys.userFirstName)
        UserDefaults.standard.set(l, forKey: Keys.userLastName)
        print("🧩 Migrated legacy userName='\(legacy)' -> first='\(f)' last='\(l)'")
    }

    private func splitNameFallback(_ full: String?) -> (String, String) {
        let s = (full ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !s.isEmpty else { return ("", "") }
        let parts = s.split(separator: " ").map(String.init)
        if parts.count == 1 { return (parts[0], "") }
        return (parts.first ?? "", parts.dropFirst().joined(separator: " "))
    }

    // MARK: - Contact Email / Update Mails

    /// Aktualisiert `contact_email` und/oder `marketing_opt_in` im Profil.
    /// - Parameters:
    ///   - contactEmail: Wenn gesetzt, wird `contact_email` aktualisiert.
    ///   - marketingOptIn: Wenn gesetzt, wird `marketing_opt_in` aktualisiert (inkl. Timestamp, wenn von false -> true).
    func updateContactPreferences(contactEmail: String? = nil, marketingOptIn: Bool? = nil) async throws {
        guard let userId = session?.user.id.uuidString else {
            throw NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Kein User eingeloggt"])
        }

        let now = ISO8601DateFormatter().string(from: Date())

        // Wenn Opt-In auf true wechselt, setzen wir einmalig ein Datum.
        let currentOptIn = UserDefaults.standard.bool(forKey: Keys.userMarketingOptIn)
        let shouldSetOptInAt = (marketingOptIn == true && currentOptIn == false)

        struct UpdateRow: Encodable {
            let id: String
            let email: String
            let contact_email: String?
            let marketing_opt_in: Bool?
            let marketing_opt_in_at: String?
            let updated_at: String
        }

        let row = UpdateRow(
            id: userId,
            email: userEmail,
            contact_email: contactEmail,
            marketing_opt_in: marketingOptIn,
            marketing_opt_in_at: shouldSetOptInAt ? now : nil,
            updated_at: now
        )

        let contactDesc = contactEmail ?? "<unchanged>"
        let marketingDesc = marketingOptIn == nil ? "<unchanged>" : String(marketingOptIn!)
        print("✉️ updateContactPreferences userId=\(userId) contact=\(contactDesc) marketing=\(marketingDesc)")

        _ = try await client
            .from("profiles")
            .upsert(row, onConflict: "id")
            .execute()

        await syncProfileFromBackendToLocal()
    }

    // MARK: - Delete Account

    /// Löscht den Account serverseitig (Edge Function mit Service Role):
    /// - löscht alle zugehörigen Rows (profiles, user_data, …)
    /// - löscht anschließend den Auth-User
    /// - räumt lokal auf
    func deleteAccountCompletely() async throws {
        guard let userId = session?.user.id.uuidString else {
            throw NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Kein User eingeloggt"])
        }

        print("🗑️ deleteAccountCompletely userId=\(userId)")

        // 1) Edge Function aufrufen (benötigt Internet)
        try await deleteAccountViaEdgeFunction()
        print("🗑️ deleteAccountCompletely: edge function success")

        // 2) Lokal ausloggen (Tokens/Session entfernen)
        do {
            try await client.auth.signOut()
        } catch {
            // Falls der User bereits gelöscht ist, kann signOut fehlschlagen – ist ok.
            print("⚠️ deleteAccountCompletely: signOut failed (continuing): \(error)")
        }

        // 3) Lokal alles
        clearLocalProfile()
        SyncStateStore.reset()
        session = nil
    }

    /// Ruft die Supabase Edge Function `delete-account` auf, die serverseitig mit Service Role
    /// a) alle App-Daten löscht und b) den Auth-User entfernt.
    private func deleteAccountViaEdgeFunction() async throws {
        let currentSession = try await client.auth.session

        let url = SupabaseConfig.url.appendingPathComponent("functions/v1/delete-account")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(currentSession.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = Data("{}".utf8)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw NSError(domain: "Auth", code: -2, userInfo: [NSLocalizedDescriptionKey: "Ungültige Server-Antwort"])
        }

        if !(200...299).contains(http.statusCode) {
            let body = String(data: data, encoding: .utf8) ?? "<kein Body>"
            throw NSError(
                domain: "Auth",
                code: http.statusCode,
                userInfo: [NSLocalizedDescriptionKey: "Account-Löschung fehlgeschlagen (HTTP \(http.statusCode)): \(body)"]
            )
        }
    }
}
