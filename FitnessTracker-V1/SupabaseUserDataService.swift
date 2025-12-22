import Foundation
import Supabase

@MainActor
final class SupabaseUserDataService {
    static let shared = SupabaseUserDataService()
    private init() {}

    private let client = SupabaseManager.shared.client

    struct UserDataRow: Codable {
        let user_id: String
        let trainings: [Training]
        let bodyweight: [BodyweightEntry]
        let updated_at: String?
    }

    struct UpsertRow: Encodable {
        let user_id: String
        let trainings: [Training]
        let bodyweight: [BodyweightEntry]
    }

    /// Pull: Lädt user_data. Wenn noch keine Zeile existiert -> nil
    func fetchUserData(userId: String) async throws -> UserDataRow? {
        do {
            let response = try await client
                .from("user_data")
                .select("user_id,trainings,bodyweight,updated_at")
                .eq("user_id", value: userId)
                .single()
                .execute()

            return try JSONDecoder().decode(UserDataRow.self, from: response.data)
        } catch {
            // Wenn noch keine Row existiert, wirft Supabase oft einen Error bei .single()
            return nil
        }
    }

    /// Push: Upsert der kompletten lokalen Daten
    func upsertUserData(userId: String, trainings: [Training], bodyweight: [BodyweightEntry]) async throws {
        let row = UpsertRow(user_id: userId, trainings: trainings, bodyweight: bodyweight)

        _ = try await client
            .from("user_data")
            .upsert(row, onConflict: "user_id")
            .execute()
    }
}
