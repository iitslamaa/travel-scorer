//
//  FriendService.swift
//  TravelScoreriOS
//

import Foundation
import Supabase
import PostgREST

private struct FriendRow: Decodable {
    let user_id: UUID
    let friend_id: UUID
}

@MainActor
final class FriendService {

    private let supabase: SupabaseManager

    init(supabase: SupabaseManager = .shared) {
        self.supabase = supabase
    }

    // MARK: - Friends

    func fetchFriends(for userId: UUID) async throws -> [Profile] {

        // Query 1: user_id = me (use UUID directly, NOT uuidString)
        let sentResponse: PostgrestResponse<[FriendRow]> = try await supabase.client
            .from("friends")
            .select("user_id, friend_id")
            .eq("user_id", value: userId)
            .execute()

        // Query 2: friend_id = me (use UUID directly)
        let receivedResponse: PostgrestResponse<[FriendRow]> = try await supabase.client
            .from("friends")
            .select("user_id, friend_id")
            .eq("friend_id", value: userId)
            .execute()

        let rows = sentResponse.value + receivedResponse.value

        print("👀 raw friend rows:", rows)

        let friendIds: [UUID] = rows.map { row in
            row.user_id == userId ? row.friend_id : row.user_id
        }

        if friendIds.isEmpty {
            print("👀 friendIds empty")
            return []
        }

        print("👀 friend IDs:", friendIds)

        let profilesResponse: PostgrestResponse<[Profile]> = try await supabase.client
            .from("profiles")
            .select("*")
            .in("id", values: friendIds)
            .execute()

        print("👀 friend profiles:", profilesResponse.value)

        return profilesResponse.value
    }

    func isFriend(currentUserId: UUID, otherUserId: UUID) async throws -> Bool {

        let filter = "and(user_id.eq.\(currentUserId.uuidString),friend_id.eq.\(otherUserId.uuidString)),and(user_id.eq.\(otherUserId.uuidString),friend_id.eq.\(currentUserId.uuidString))"

        let response = try await supabase.client
            .from("friends")
            .select("id", count: .exact)
            .or(filter)
            .limit(1)
            .execute()

        return (response.count ?? 0) > 0
    }

    func removeFriend(myUserId: UUID, otherUserId: UUID) async throws {

        let filter = "and(user_id.eq.\(myUserId.uuidString),friend_id.eq.\(otherUserId.uuidString)),and(user_id.eq.\(otherUserId.uuidString),friend_id.eq.\(myUserId.uuidString))"

        try await supabase.client
            .from("friends")
            .delete()
            .or(filter)
            .execute()

        print("🗑 Removed friendship between:", myUserId, "and", otherUserId)
    }

    func fetchMutualFriends(currentUserId: UUID, otherUserId: UUID) async throws -> [Profile] {
        let currentFriends = try await fetchFriends(for: currentUserId)
        let otherFriends = try await fetchFriends(for: otherUserId)

        let currentSet = Set(currentFriends.map { $0.id })
        let mutual = otherFriends.filter { currentSet.contains($0.id) }

        return mutual.sorted {
            $0.username < $1.username
        }
    }

    // MARK: - Requests

    func fetchIncomingRequests(for myUserId: UUID) async throws -> [Profile] {
        let response: PostgrestResponse<[IncomingRequestJoinedRow]> = try await supabase.client
            .from("friend_requests")
            .select("""
                id,
                sender_id,
                profiles!friend_requests_sender_id_fkey (*)
            """)
            .eq("receiver_id", value: myUserId)
            .eq("status", value: "pending")
            .execute()

        return response.value.map { $0.profile }
    }

    func incomingRequestCount(for myUserId: UUID) async throws -> Int {

        struct RequestIDRow: Decodable { let id: UUID }

        let response: PostgrestResponse<[RequestIDRow]> = try await supabase.client
            .from("friend_requests")
            .select("id")
            .eq("receiver_id", value: myUserId)
            .eq("status", value: "pending")
            .execute()

        return response.value.count
    }

    func fetchPendingRequestCount(for userId: UUID) async throws -> Int {
        try await incomingRequestCount(for: userId)
    }

    func hasIncomingRequest(from otherUserId: UUID, to myUserId: UUID) async throws -> Bool {

        struct RequestIDRow: Decodable { let id: UUID }

        let response: PostgrestResponse<[RequestIDRow]> = try await supabase.client
            .from("friend_requests")
            .select("id")
            .eq("sender_id", value: otherUserId)
            .eq("receiver_id", value: myUserId)
            .eq("status", value: "pending")
            .limit(1)
            .execute()

        return !response.value.isEmpty
    }

    func hasSentRequest(from myUserId: UUID, to otherUserId: UUID) async throws -> Bool {

        struct RequestIDRow: Decodable { let id: UUID }

        let response: PostgrestResponse<[RequestIDRow]> = try await supabase.client
            .from("friend_requests")
            .select("id")
            .eq("sender_id", value: myUserId)
            .eq("receiver_id", value: otherUserId)
            .eq("status", value: "pending")
            .limit(1)
            .execute()

        return !response.value.isEmpty
    }

    func sendFriendRequest(from myUserId: UUID, to otherUserId: UUID) async throws {

        guard myUserId != otherUserId else { return }

        if try await isFriend(currentUserId: myUserId, otherUserId: otherUserId) { return }
        if try await hasIncomingRequest(from: otherUserId, to: myUserId) { return }
        if try await hasSentRequest(from: myUserId, to: otherUserId) { return }

        struct FriendRequestInsert: Encodable {
            let sender_id: UUID
            let receiver_id: UUID
            let status: String
        }

        let payload = FriendRequestInsert(
            sender_id: myUserId,
            receiver_id: otherUserId,
            status: "pending"
        )

        try await supabase.client
            .from("friend_requests")
            .insert(payload)
            .execute()
    }

    func cancelRequest(from myUserId: UUID, to otherUserId: UUID) async throws {

        try await supabase.client
            .from("friend_requests")
            .delete()
            .eq("sender_id", value: myUserId)
            .eq("receiver_id", value: otherUserId)
            .eq("status", value: "pending")
            .execute()
    }

    func acceptRequest(myUserId: UUID, from otherUserId: UUID) async throws {

        // Remove pending request
        try await supabase.client
            .from("friend_requests")
            .delete()
            .eq("sender_id", value: otherUserId)
            .eq("receiver_id", value: myUserId)
            .execute()

        // Insert ONE friendship row
        try await supabase.client
            .from("friends")
            .insert([
                "user_id": myUserId,
                "friend_id": otherUserId
            ])
            .execute()
    }

    func rejectRequest(myUserId: UUID, from otherUserId: UUID) async throws {

        try await supabase.client
            .from("friend_requests")
            .delete()
            .eq("sender_id", value: otherUserId)
            .eq("receiver_id", value: myUserId)
            .execute()
    }
}

private struct IncomingRequestJoinedRow: Decodable {
    let profile: Profile
    enum CodingKeys: String, CodingKey { case profile = "profiles" }
}
