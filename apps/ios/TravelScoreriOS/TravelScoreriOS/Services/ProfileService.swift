//
//  ProfileService.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 2/6/26.
//

import Foundation
import Supabase
import PostgREST

struct ProfileInsert: Encodable {
    let id: UUID
    let username: String?
    let avatarUrl: String?

    enum CodingKeys: String, CodingKey {
        case id
        case username
        case avatarUrl = "avatar_url"
    }
}

struct ProfileUpdate: Encodable {
    let username: String?
    let fullName: String?
    let avatarUrl: String?
    let languages: [String]?
    let livedCountries: [String]?
    let travelStyle: [String]?
    let travelMode: [String]?
    let onboardingCompleted: Bool?

    enum CodingKeys: String, CodingKey {
        case username
        case fullName = "full_name"
        case avatarUrl = "avatar_url"
        case languages
        case livedCountries = "lived_countries"
        case travelStyle = "travel_style"
        case travelMode = "travel_mode"
        case onboardingCompleted = "onboarding_completed"
    }
}

@MainActor
final class ProfileService {

    private let supabase: SupabaseManager

    init(supabase: SupabaseManager) {
        self.supabase = supabase
    }

    // MARK: - Fetch

    func fetchMyProfile(userId: UUID) async throws -> Profile {
        try await supabase.client
            .from("profiles")
            .select()
            .eq("id", value: userId.uuidString)
            .single()
            .execute()
            .value
    }

    func ensureProfileExists(
        userId: UUID,
        defaultUsername: String? = nil,
        defaultAvatarUrl: String? = nil
    ) async throws {
        do {
            // Attempt to fetch profile
            _ = try await fetchMyProfile(userId: userId)
        } catch {
            // If not found, create it
            let insert = ProfileInsert(
                id: userId,
                username: defaultUsername,
                avatarUrl: defaultAvatarUrl
            )

            try await supabase.client
                .from("profiles")
                .insert(insert)
                .execute()
        }
    }

    func fetchOrCreateProfile(
        userId: UUID,
        defaultUsername: String? = nil,
        defaultAvatarUrl: String? = nil
    ) async throws -> Profile {
        do {
            return try await fetchMyProfile(userId: userId)
        } catch {
            let insert = ProfileInsert(
                id: userId,
                username: defaultUsername,
                avatarUrl: defaultAvatarUrl
            )

            try await supabase.client
                .from("profiles")
                .insert(insert)
                .execute()

            return try await fetchMyProfile(userId: userId)
        }
    }

    // MARK: - Update

    func updateProfile(
        userId: UUID,
        payload: ProfileUpdate
    ) async throws {
        try await supabase.client
            .from("profiles")
            .update(payload)
            .eq("id", value: userId.uuidString)
            .execute()
    }

    // MARK: - Avatar Storage

    func uploadAvatar(
        data: Data,
        path: String
    ) async throws {

        try await supabase.client.storage
            .from("avatars")
            .upload(
                path: path,
                file: data,
                options: FileOptions(
                    cacheControl: "3600",
                    contentType: "image/jpeg",
                    upsert: true
                )
            )
    }

    func publicAvatarURL(path: String) throws -> String {
        try supabase.client.storage
            .from("avatars")
            .getPublicURL(path: path)
            .absoluteString
    }

    // MARK: - Viewed user stats

    /// Traveled countries for the currently authenticated user
    func fetchMyTraveledCountries() async throws -> Set<String> {
        guard let myUserId = supabase.currentUserId else { return [] }

        let response: PostgrestResponse<[String]> = try await supabase.client
            .from("traveled_countries")
            .select("country_code")
            .eq("user_id", value: myUserId.uuidString)
            .execute()

        return Set(response.value)
    }

    /// Bucket list countries for the currently authenticated user
    func fetchMyBucketListCountries() async throws -> Set<String> {
        guard let myUserId = supabase.currentUserId else { return [] }

        let response: PostgrestResponse<[String]> = try await supabase.client
            .from("bucket_list")
            .select("country_code")
            .eq("user_id", value: myUserId.uuidString)
            .execute()

        return Set(response.value)
    }

    /// Traveled countries for any viewed user
    func fetchTraveledCountries(userId: UUID) async throws -> Set<String> {
        let response: PostgrestResponse<[String]> = try await supabase.client
            .from("traveled_countries")
            .select("country_code")
            .eq("user_id", value: userId.uuidString)
            .execute()

        return Set(response.value)
    }

    /// Bucket list countries for any viewed user
    func fetchBucketListCountries(userId: UUID) async throws -> Set<String> {
        let response: PostgrestResponse<[String]> = try await supabase.client
            .from("bucket_list")
            .select("country_code")
            .eq("user_id", value: userId.uuidString)
            .execute()

        return Set(response.value)
    }
}
