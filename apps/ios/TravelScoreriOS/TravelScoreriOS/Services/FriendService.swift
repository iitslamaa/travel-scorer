//
//  FriendService.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 2/11/26.
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
        let uid = userId.uuidString

        let response: PostgrestResponse<[FriendRow]> = try await supabase.client
            .from("friends")
            .select("user_id, friend_id")
            .or("user_id.eq.\(uid),friend_id.eq.\(uid)")
            .execute()

        let rows = response.value

        let friendIds: [String] = rows.map { row in
            row.user_id == userId ? row.friend_id.uuidString : row.user_id.uuidString
        }

        if friendIds.isEmpty { return [] }

        let profilesResponse: PostgrestResponse<[Profile]> = try await supabase.client
            .from("profiles")
            .select("*")
            .in("id", values: friendIds)
            .execute()

        return profilesResponse.value
    }

    func isFriend(currentUserId: UUID, otherUserId: UUID) async throws -> Bool {
        let a = currentUserId.uuidString
        let b = otherUserId.uuidString

        let response = try await supabase.client
            .from("friends")
            .select("id", count: .exact)
            .or("and(user_id.eq.\(a),friend_id.eq.\(b)),and(user_id.eq.\(b),friend_id.eq.\(a))")
            .limit(1)
            .execute()

        return (response.count ?? 0) > 0
    }

    /// Unfriend: remove BOTH directions
    func removeFriend(myUserId: UUID, otherUserId: UUID) async throws {
        let a = myUserId.uuidString
        let b = otherUserId.uuidString

        try await supabase.client
            .from("friends")
            .delete()
            .or("and(user_id.eq.\(a),friend_id.eq.\(b)),and(user_id.eq.\(b),friend_id.eq.\(a))")
            .execute()
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
            .eq("receiver_id", value: myUserId.uuidString)
            .eq("status", value: "pending")
            .execute()

        return response.value.map { $0.profile }
    }

    func incomingRequestCount(for myUserId: UUID) async throws -> Int {
        let response: PostgrestResponse<[UUID]> = try await supabase.client
            .from("friend_requests")
            .select("id")
            .eq("receiver_id", value: myUserId.uuidString)
            .eq("status", value: "pending")
            .execute()

        return response.value.count
    }

    func hasIncomingRequest(from otherUserId: UUID, to myUserId: UUID) async throws -> Bool {
        struct RequestIDRow: Decodable { let id: UUID }

        let response: PostgrestResponse<[RequestIDRow]> = try await supabase.client
            .from("friend_requests")
            .select("id")
            .eq("sender_id", value: otherUserId.uuidString)
            .eq("receiver_id", value: myUserId.uuidString)
            .eq("status", value: "pending")
            .limit(1)
            .execute()

        return !response.value.isEmpty
    }

    func sendFriendRequest(from myUserId: UUID, to otherUserId: UUID) async throws {
        // 1) Prevent self-request
        guard myUserId != otherUserId else { return }

        // 2) Already friends → no-op
        if try await isFriend(currentUserId: myUserId, otherUserId: otherUserId) {
            return
        }

        // 3) If they already requested you → no-op (could auto-accept later)
        if try await hasIncomingRequest(from: otherUserId, to: myUserId) {
            return
        }

        // 4) If you already sent request → no-op
        if try await hasSentRequest(from: myUserId, to: otherUserId) {
            return
        }

        do {
            try await supabase.client
                .from("friend_requests")
                .insert([
                    "sender_id": myUserId.uuidString,
                    "receiver_id": otherUserId.uuidString,
                    "status": "pending"
                ])
                .execute()
        } catch {
            if let pgError = error as? PostgrestError, pgError.code == "23505" {
                return
            }
            throw error
        }
    }

    func hasSentRequest(from myUserId: UUID, to otherUserId: UUID) async throws -> Bool {
        struct RequestIDRow: Decodable { let id: UUID }

        let response: PostgrestResponse<[RequestIDRow]> = try await supabase.client
            .from("friend_requests")
            .select("id")
            .eq("sender_id", value: myUserId.uuidString)
            .eq("receiver_id", value: otherUserId.uuidString)
            .eq("status", value: "pending")
            .limit(1)
            .execute()

        return !response.value.isEmpty
    }

    func acceptRequest(myUserId: UUID, from otherUserId: UUID) async throws {
        // 1) Delete pending request (ignore if missing)
        _ = try? await supabase.client
            .from("friend_requests")
            .delete()
            .eq("sender_id", value: otherUserId.uuidString)
            .eq("receiver_id", value: myUserId.uuidString)
            .execute()

        // 2) Insert both directions (ignore duplicate constraint errors)
        do {
            try await supabase.client
                .from("friends")
                .insert([
                    "user_id": myUserId.uuidString,
                    "friend_id": otherUserId.uuidString
                ])
                .execute()
        } catch {
            if let pgError = error as? PostgrestError, pgError.code != "23505" { throw error }
        }

        do {
            try await supabase.client
                .from("friends")
                .insert([
                    "user_id": otherUserId.uuidString,
                    "friend_id": myUserId.uuidString
                ])
                .execute()
        } catch {
            if let pgError = error as? PostgrestError, pgError.code != "23505" { throw error }
        }
    }

    func rejectRequest(myUserId: UUID, from otherUserId: UUID) async throws {
        try await supabase.client
            .from("friend_requests")
            .delete()
            .eq("sender_id", value: otherUserId.uuidString)
            .eq("receiver_id", value: myUserId.uuidString)
            .execute()
    }
}

// MARK: - DTO for joined incoming request row

private struct IncomingRequestJoinedRow: Decodable {
    let profile: Profile
    enum CodingKeys: String, CodingKey { case profile = "profiles" }
}
