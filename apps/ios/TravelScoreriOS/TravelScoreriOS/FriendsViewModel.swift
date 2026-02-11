//
//  FriendsViewModel.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 2/10/26.
//

import Foundation
import Combine
import SwiftUI

@MainActor
final class FriendsViewModel: ObservableObject {

    // MARK: - Published state
    @Published var searchText: String = ""
    @Published var searchResults: [Profile] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var friends: [Profile] = []

    // MARK: - Dependencies
    private let supabase = SupabaseManager.shared

    // MARK: - Load Friends

    func loadFriends() async {
        guard let userId = supabase.currentUserId else { return }

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
