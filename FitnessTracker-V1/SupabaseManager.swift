import Foundation
import Supabase

enum SupabaseConfig {
    static let url = URL(string: "https://xeltkspvrceeypxzawpn.supabase.co")!
    static let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhlbHRrc3B2cmNlZXlweHphd3BuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjYxNDI0NDQsImV4cCI6MjA4MTcxODQ0NH0.yD43BVpn3bEyrXWszaFI68p690IOCA3e5Hoh6mPWGX8"

    /// Hinweis: Für natives iOS Sign in with Apple brauchst du typischerweise ein Custom Scheme Redirect.
    /// In deinem aktuellen Projekt nutzt du bereits den Supabase Callback; das ist für den MVP ok.
    static let redirectURL = URL(string: "https://xeltkspvrceeypxzawpn.supabase.co/auth/v1/callback")!
}

final class SupabaseManager {
    static let shared = SupabaseManager()
    let client: SupabaseClient

    private init() {
        // Offline-first:
        // - lokale Session als Initial-Event emittieren (wichtig für Flugmodus)
        // - auto refresh token aktiviert lassen
        //
        // Falls dein supabase-swift Package diese Options-Struktur nicht kennt (Compile-Fehler),
        // sag kurz Bescheid – dann passe ich es exakt an deine SDK-Version an.
        self.client = SupabaseClient(
            supabaseURL: SupabaseConfig.url,
            supabaseKey: SupabaseConfig.anonKey,
            options: .init(
                auth: .init(
                    autoRefreshToken: true,
                    emitLocalSessionAsInitialSession: true
                )
            )
        )
    }
}
