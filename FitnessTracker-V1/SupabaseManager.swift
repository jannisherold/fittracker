import Foundation
import Supabase

enum SupabaseConfig {
    // ✅ HIER deine Werte eintragen
    static let url = URL(string: "https://xeltkspvrceeypxzawpn.supabase.co")!
    static let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhlbHRrc3B2cmNlZXlweHphd3BuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjYxNDI0NDQsImV4cCI6MjA4MTcxODQ0NH0.yD43BVpn3bEyrXWszaFI68p690IOCA3e5Hoh6mPWGX8"
    
    /// OAuth Redirect (Custom Scheme) – muss auch in Supabase Auth → URL Configuration als Redirect URL erlaubt sein
    /// Beispiel: fitnesstrackerv1://login-callback
    static let redirectURL = URL(string: "https://xeltkspvrceeypxzawpn.supabase.co/auth/v1/callback")!
}

final class SupabaseManager {
    static let shared = SupabaseManager()
    let client: SupabaseClient

    private init() {
        self.client = SupabaseClient(
            supabaseURL: SupabaseConfig.url,
            supabaseKey: SupabaseConfig.anonKey
        )
    }
}
