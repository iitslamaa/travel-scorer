import Foundation
import Combine
import Supabase

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

    /// Check whether the current user is friends with another user
    func isFriend(currentUserId: UUID, otherUserId: UUID) async throws -> Bool {
        let response = try await client
            .from("friends")
            .select("id", count: .exact)
            .eq("user_id", value: currentUserId.uuidString)
            .eq("friend_id", value: otherUserId.uuidString)
            .limit(1)
            .execute()

        return (response.count ?? 0) > 0
    }
}
