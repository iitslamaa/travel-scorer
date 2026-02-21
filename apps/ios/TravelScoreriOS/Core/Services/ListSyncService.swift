//
//  ListSyncService.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 2/6/26.
//

import Foundation
import Supabase
import PostgREST

@MainActor
final class ListSyncService {

    private let instanceId = UUID()

    private let supabase: SupabaseManager

    init(supabase: SupabaseManager) {
        self.supabase = supabase
        print("🧠 ListSyncService INIT — instance:", instanceId)
    }

    // MARK: - Fetch

    func fetchBucketList(userId: UUID) async throws -> Set<String> {
        print("🪣 [ListSync:", instanceId, "] fetchBucketList START for:", userId)
        let rows: [[String: String]] = try await supabase.client
            .from("user_bucket_list")
            .select("country_id")
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value

        print("🪣 [ListSync:", instanceId, "] fetched bucket rows:", rows)
        return Set(rows.compactMap { $0["country_id"] })
    }

    func fetchTraveled(userId: UUID) async throws -> Set<String> {
        print("✈️ [ListSync:", instanceId, "] fetchTraveled START for:", userId)
        let rows: [[String: String]] = try await supabase.client
            .from("user_traveled")
            .select("country_id")
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value

        print("✈️ [ListSync:", instanceId, "] fetched traveled rows:", rows)
        return Set(rows.compactMap { $0["country_id"] })
    }

    // MARK: - Mutations

    func setBucket(
        userId: UUID,
        countryId: String,
        add: Bool
    ) async {
        print("🪣 [ListSync:", instanceId, "] setBucket — user:", userId, "country:", countryId, "add:", add)
        do {
            if add {
                try await supabase.client
                    .from("user_bucket_list")
                    .insert([
                        "user_id": userId.uuidString,
                        "country_id": countryId
                    ])
                    .execute()
            } else {
                try await supabase.client
                    .from("user_bucket_list")
                    .delete()
                    .eq("user_id", value: userId.uuidString)
                    .eq("country_id", value: countryId)
                    .execute()
            }
        } catch {
            print("❌ [ListSync:", instanceId, "] setBucket failed:", error)
        }
    }

    func setTraveled(
        userId: UUID,
        countryId: String,
        add: Bool
    ) async {
        print("✈️ [ListSync:", instanceId, "] setTraveled — user:", userId, "country:", countryId, "add:", add)
        do {
            if add {
                try await supabase.client
                    .from("user_traveled")
                    .insert([
                        "user_id": userId.uuidString,
                        "country_id": countryId
                    ])
                    .execute()
            } else {
                try await supabase.client
                    .from("user_traveled")
                    .delete()
                    .eq("user_id", value: userId.uuidString)
                    .eq("country_id", value: countryId)
                    .execute()
            }
        } catch {
            print("❌ [ListSync:", instanceId, "] setTraveled failed:", error)
        }
    }

    deinit {
        print("💀 ListSyncService DEINIT — instance:", instanceId)
    }
}
