//
//  FriendsViewModel.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 2/10/26.
//

import Foundation
import Combine
import SwiftUI
import PostgREST
import Supabase

@MainActor
final class FriendsViewModel: ObservableObject {

    // MARK: - Published state
    @Published var searchText: String = ""
    @Published var searchResults: [Profile] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var friends: [Profile] = []
    @Published var incomingRequestCount: Int = 0

    // MARK: - Dependencies
    private let supabase = SupabaseManager.shared

    // MARK: - Load Friends

    func loadFriends(for userId: UUID) async {
        isLoading = true
        errorMessage = nil

        do {
            friends = try await supabase.fetchFriends(for: userId)
        } catch {
            errorMessage = error.localizedDescription
            friends = []
        }

        isLoading = false
    }

    // MARK: - Incoming Requests Count

    func loadIncomingRequestCount() async {
        guard let userId = supabase.currentUserId else { return }

        do {
            let response: PostgrestResponse<[UUID]> = try await supabase.client
                .from("friend_requests")
                .select("id")
                .eq("receiver_id", value: userId.uuidString)
                .eq("status", value: "pending")
                .execute()

            incomingRequestCount = response.value.count
        } catch {
            incomingRequestCount = 0
        }
    }

    // MARK: - Search

    func searchUsers() async {
        guard !searchText.trimmingCharacters(in: .whitespaces).isEmpty else {
            searchResults = []
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            searchResults = try await supabase.searchUsers(byUsername: searchText)
        } catch {
            errorMessage = error.localizedDescription
            searchResults = []
        }

        isLoading = false
    }

    // MARK: - Helpers

    func clearSearch() {
        searchText = ""
        searchResults = []
        errorMessage = nil
    }
}
