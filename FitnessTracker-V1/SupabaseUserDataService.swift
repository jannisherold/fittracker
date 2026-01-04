import Foundation
import Supabase

@MainActor
final class SupabaseUserDataService {
    static let shared = SupabaseUserDataService()
    private init() {}

    private let client = SupabaseManager.shared.client

    struct UserDataRow: Codable {
        let user_id: String
        let trainings: [Training]?
        let bodyweight: [BodyweightEntry]?
        let rest_timer_enabled: Bool?
        let rest_timer_seconds: Int?
        let updated_at: String?
    }

    struct UpsertRow: Encodable {
        let user_id: String
        let trainings: [Training]
        let bodyweight: [BodyweightEntry]
        let rest_timer_enabled: Bool
        let rest_timer_seconds: Int
    }

    func fetchUserData(userId: String) async throws -> UserDataRow? {
        let response = try await client
            .from("user_data")
            .select("user_id,trainings,bodyweight,rest_timer_enabled,rest_timer_seconds,updated_at")
            .eq("user_id", value: userId)
            .limit(1)
            .execute()

        let rows = try JSONDecoder().decode([UserDataRow].self, from: response.data)
        return rows.first
    }

    func upsertUserData(
        userId: String,
        trainings: [Training],
        bodyweight: [BodyweightEntry],
        restTimerEnabled: Bool,
        restTimerSeconds: Int
    ) async throws {
        let row = UpsertRow(
            user_id: userId,
            trainings: trainings,
            bodyweight: bodyweight,
            rest_timer_enabled: restTimerEnabled,
            rest_timer_seconds: restTimerSeconds
        )

        _ = try await client
            .from("user_data")
            .upsert(row, onConflict: "user_id")
            .execute()
    }
}
