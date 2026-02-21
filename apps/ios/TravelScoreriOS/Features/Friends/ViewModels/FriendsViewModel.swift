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
    private let instanceId = UUID()

    // MARK: - Published state
    @Published var searchText: String = ""
    @Published var searchResults: [Profile] = [] {
        didSet {
            print("📡 [FriendsVM:", instanceId, "] searchResults DID SET — count:", searchResults.count)
        }
    }
    @Published var isLoading: Bool = false {
        didSet {
            print("📡 [FriendsVM:", instanceId, "] isLoading DID SET —", isLoading)
        }
    }
    @Published var errorMessage: String?
    @Published var friends: [Profile] = [] {
        didSet {
            print("📡 [FriendsVM:", instanceId, "] friends DID SET — count:", friends.count)
        }
    }
    @Published var incomingRequestCount: Int = 0 {
        didSet {
            print("📡 [FriendsVM:", instanceId, "] incomingRequestCount DID SET —", incomingRequestCount)
        }
    }
    @Published var displayName: String = "" {
        didSet {
            print("📡 [FriendsVM:", instanceId, "] displayName DID SET —", displayName)
        }
    }
    @Published private(set) var hasLoaded: Bool = false

    // MARK: - Dependencies
    private let supabase = SupabaseManager.shared
    private let friendService = FriendService()

    // MARK: - Init / Deinit

    init() {
        print("🧠 FriendsViewModel INIT — instance:", instanceId)
    }

    deinit {
        print("💀 FriendsViewModel DEINIT — instance:", instanceId)
    }

    // MARK: - Load Friends

    func loadFriends(for userId: UUID, forceRefresh: Bool = false) async {
        if hasLoaded && !forceRefresh {
            print("⏭ [FriendsVM:", instanceId, "] loadFriends skipped (already loaded)")
            return
        }

        print("👥 [FriendsVM:", instanceId, "] loadFriends START for:", userId, "force:", forceRefresh)
        isLoading = true
        errorMessage = nil

        do {
            let fetchedFriends = try await friendService.fetchFriends(for: userId)
            friends = fetchedFriends
            hasLoaded = true
            print("👥 [FriendsVM:", instanceId, "] loadFriends result count:", friends.count)
        } catch {
            print("❌ [FriendsVM:", instanceId, "] loadFriends failed:", error)
            errorMessage = error.localizedDescription
            friends = []
        }

        isLoading = false
    }

    // MARK: - Load Display Name

    func loadDisplayName(for userId: UUID) async {
        print("🏷 [FriendsVM:", instanceId, "] loadDisplayName for:", userId)
        do {
            let response: PostgrestResponse<Profile> = try await supabase.client
                .from("profiles")
                .select("*")
                .eq("id", value: userId.uuidString)
                .single()
                .execute()

            displayName = response.value.fullName
            print("🏷 [FriendsVM:", instanceId, "] displayName loaded:", displayName)
        } catch {
            print("❌ [FriendsVM:", instanceId, "] loadDisplayName failed:", error)
            displayName = ""
        }
    }

    // MARK: - Incoming Requests Count

    func loadIncomingRequestCount() async {
        print("🔔 [FriendsVM:", instanceId, "] loadIncomingRequestCount")
        guard let userId = supabase.currentUserId else { return }

        do {
            incomingRequestCount = try await friendService.incomingRequestCount(for: userId)
            print("🔔 [FriendsVM:", instanceId, "] incomingRequestCount:", incomingRequestCount)
        } catch {
            print("❌ [FriendsVM:", instanceId, "] loadIncomingRequestCount failed:", error)
            incomingRequestCount = 0
        }
    }

    // MARK: - Search

    func searchUsers() async {
        print("🔎 [FriendsVM:", instanceId, "] searchUsers for:", searchText)
        guard !searchText.trimmingCharacters(in: .whitespaces).isEmpty else {
            searchResults = []
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            searchResults = try await supabase.searchUsers(byUsername: searchText)
            print("🔎 [FriendsVM:", instanceId, "] searchUsers results count:", searchResults.count)
        } catch {
            print("❌ [FriendsVM:", instanceId, "] searchUsers failed:", error)
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
