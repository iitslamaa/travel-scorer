//
//  FriendRequestsViewModel.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 2/10/26.
//

import Foundation
import Combine
import Supabase

@MainActor
final class FriendRequestsViewModel: ObservableObject {

    // MARK: - Published state
    @Published var incomingRequests: [Profile] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // MARK: - Dependencies
    private let supabase = SupabaseManager.shared

    // MARK: - Fetch incoming requests

    func loadIncomingRequests() async {
        guard let myUserId = supabase.currentUserId else { return }

        isLoading = true
        errorMessage = nil

        do {
            let response: PostgrestResponse<[FriendRequestRow]> = try await supabase.client
                .from("friend_requests")
                .select("""
                    id,
                    sender_id,
                    profiles!friend_requests_sender_id_fkey (*)
                """)
                .eq("receiver_id", value: myUserId.uuidString)
                .eq("status", value: "pending")
                .execute()

            incomingRequests = response.value.map { $0.profile }
        } catch {
            errorMessage = error.localizedDescription
            incomingRequests = []
        }

        isLoading = false
    }

    // MARK: - Send request

    func sendFriendRequest(to userId: UUID) async throws {
        guard let myUserId = supabase.currentUserId else { return }

        try await supabase.client
            .from("friend_requests")
            .insert([
                "sender_id": myUserId.uuidString,
                "receiver_id": userId.uuidString,
                "status": "pending"
            ])
            .execute()
    }

    // MARK: - Request state helpers

    /// Returns true if the current user has already sent a friend request to the given user
    func hasSentRequest(to userId: UUID) async throws -> Bool {
        guard let myUserId = supabase.currentUserId else { return false }

        struct RequestIDRow: Decodable {
            let id: UUID
        }

        let response: PostgrestResponse<[RequestIDRow]> = try await supabase.client
            .from("friend_requests")
            .select("id")
            .eq("sender_id", value: myUserId.uuidString)
            .eq("receiver_id", value: userId.uuidString)
            .eq("status", value: "pending")
            .limit(1)
            .execute()

        return !response.value.isEmpty
    }

    // MARK: - Accept request

    func acceptRequest(from userId: UUID) async throws {
        guard let myUserId = supabase.currentUserId else { return }

        // 1. Delete request
        try await supabase.client
            .from("friend_requests")
            .delete()
            .eq("sender_id", value: userId.uuidString)
            .eq("receiver_id", value: myUserId.uuidString)
            .execute()

        // 2. Create mutual friendship
        try await supabase.client
            .from("friends")
            .insert([
                ["user_id": myUserId.uuidString, "friend_id": userId.uuidString],
                ["user_id": userId.uuidString, "friend_id": myUserId.uuidString]
            ])
            .execute()
    }

    // MARK: - Reject request

    func rejectRequest(from userId: UUID) async throws {
        guard let myUserId = supabase.currentUserId else { return }

        try await supabase.client
            .from("friend_requests")
            .delete()
            .eq("sender_id", value: userId.uuidString)
            .eq("receiver_id", value: myUserId.uuidString)
            .execute()
    }
}

// MARK: - Private DTOs

private struct FriendRequestRow: Decodable {
    let profile: Profile

    enum CodingKeys: String, CodingKey {
        case profile = "profiles"
    }
}
