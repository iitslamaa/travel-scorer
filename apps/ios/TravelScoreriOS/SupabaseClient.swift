/// SupabaseClient.swift

import Foundation
import Combine
import Supabase

private struct FriendRow: Decodable {
    let user_id: UUID
    let friend_id: UUID
}

/// Low-level Supabase wrapper.
/// ❗️Not MainActor. Not UI. No SwiftUI state.
final class SupabaseManager {
    static let shared = SupabaseManager()

    let client: SupabaseClient

    // Emits whenever auth state changes (sign in / sign out)
    private let authStateSubject = PassthroughSubject<Void, Never>()
    var authStatePublisher: AnyPublisher<Void, Never> {
        authStateSubject.eraseToAnyPublisher()
    }

    private init() {
        guard
            let urlString = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
            let anonKey = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String,
            let url = URL(string: urlString)
        else {
            fatalError("Missing Supabase credentials in Info.plist")
        }

        self.client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: anonKey,
            options: SupabaseClientOptions(
                auth: .init(
                    emitLocalSessionAsInitialSession: true
                )
            )
        )
    }

    func startAuthListener() async {
        await client.auth.onAuthStateChange { [weak self] _, _ in
            Task { @MainActor in
                self?.authStateSubject.send(())
            }
        }
    }

    // MARK: - Session

    /// Supabase SDK exposes session asynchronously
    func fetchCurrentSession() async throws -> Session? {
        try await client.auth.session
    }

    // MARK: - Auth helpers

    func signOut() async throws {
        try await client.auth.signOut()
        authStateSubject.send(())
    }

    // MARK: - User + Friends Queries

    /// Returns the currently authenticated user's ID
    var currentUserId: UUID? {
        client.auth.currentUser?.id
    }

    /// Search users by username (case-insensitive, partial match)
    func searchUsers(byUsername query: String) async throws -> [Profile] {
        let response: PostgrestResponse<[Profile]> = try await client
            .from("profiles")
            .select("*")
            .ilike("username", pattern: "%\(query)%")
            .limit(20)
            .execute()

        return response.value
    }

    /// Add a friend relationship (current user -> friend)
    func addFriend(friendId: UUID) async throws {
        guard let userId = currentUserId else { return }

        try await client
            .from("friends")
            .insert([
                "user_id": userId.uuidString,
                "friend_id": friendId.uuidString
            ])
            .execute()
    }

    /// Remove a friend relationship (current user -> friend)
    func removeFriend(friendId: UUID) async throws {
        guard let userId = currentUserId else { return }

        try await client
            .from("friends")
            .delete()
            .eq("user_id", value: userId.uuidString)
            .eq("friend_id", value: friendId.uuidString)
            .execute()
    }

    /// Check whether two users are friends (bidirectional)
    func isFriend(currentUserId: UUID, otherUserId: UUID) async throws -> Bool {
        let a = currentUserId.uuidString
        let b = otherUserId.uuidString

        let response = try await client
            .from("friends")
            .select("id", count: .exact)
            .or("and(user_id.eq.\(a),friend_id.eq.\(b)),and(user_id.eq.\(b),friend_id.eq.\(a))")
            .limit(1)
            .execute()

        return (response.count ?? 0) > 0
    }

    /// Fetch all friends for a user
    func fetchFriends(for userId: UUID) async throws -> [Profile] {
        let uid = userId.uuidString

        // 1️⃣ Fetch all friendship rows involving this user
        let response: PostgrestResponse<[FriendRow]> = try await client
            .from("friends")
            .select("user_id, friend_id")
            .or("user_id.eq.\(uid),friend_id.eq.\(uid)")
            .execute()

        let rows = response.value

        // 2️⃣ Extract the OTHER user id in each row (compare as UUID, not String)
        let friendIds: [String] = rows.map { row in
            row.user_id == userId ? row.friend_id.uuidString : row.user_id.uuidString
        }

        if friendIds.isEmpty { return [] }

        // 3️⃣ Fetch profiles for those ids
        let profilesResponse: PostgrestResponse<[Profile]> = try await client
            .from("profiles")
            .select("*")
            .in("id", values: friendIds)
            .execute()

        return profilesResponse.value
    }
}
