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
    private let friendService = FriendService()

    // MARK: - Fetch incoming requests

    func loadIncomingRequests() async {
        guard let myUserId = supabase.currentUserId else { return }

        isLoading = true
        errorMessage = nil

        do {
            incomingRequests = try await friendService.fetchIncomingRequests(for: myUserId)
        } catch {
            errorMessage = error.localizedDescription
            incomingRequests = []
        }

        isLoading = false
    }

    // MARK: - Send request

    func sendFriendRequest(to userId: UUID) async throws {
        guard let myUserId = supabase.currentUserId else { return }
        try await friendService.sendFriendRequest(from: myUserId, to: userId)
    }

    // MARK: - Request state helpers

    /// Returns true if the current user has already sent a friend request to the given user
    func hasSentRequest(to userId: UUID) async throws -> Bool {
        guard let myUserId = supabase.currentUserId else { return false }
        return try await friendService.hasSentRequest(from: myUserId, to: userId)
    }

    // MARK: - Accept request

    func acceptRequest(from userId: UUID) async throws {
        guard let myUserId = supabase.currentUserId else { return }
        try await friendService.acceptRequest(myUserId: myUserId, from: userId)
    }

    // MARK: - Reject request

    func rejectRequest(from userId: UUID) async throws {
        guard let myUserId = supabase.currentUserId else { return }
        try await friendService.rejectRequest(myUserId: myUserId, from: userId)
    }
}
