//
//  ProfileViewModel.swift
//  TravelScoreriOS
//


import Foundation
import Combine
import PostgREST

enum RelationshipState {
    case selfProfile
    case none
    case requestSent
    case friends
}

@MainActor
final class ProfileViewModel: ObservableObject {

    // MARK: - Published state
    @Published var profile: Profile?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isFriend: Bool = false
    @Published var isFriendLoading: Bool = false
    @Published var relationshipState: RelationshipState = .none
    @Published var viewedTraveledCountries: Set<String> = []
    @Published var viewedBucketListCountries: Set<String> = []

    // MARK: - Dependencies
    private let profileService: ProfileService
    private let supabase = SupabaseManager.shared
    private let friendRequestsVM = FriendRequestsViewModel()
    private var userId: UUID?

    // MARK: - Init
    init(profileService: ProfileService) {
        self.profileService = profileService
    }

    // MARK: - User binding

    func setUserIdIfNeeded(_ newUserId: UUID) {
        if userId == newUserId { return }

        print("🔁 ProfileViewModel binding userId:", newUserId)

        userId = newUserId
        profile = nil
        errorMessage = nil
        viewedTraveledCountries = []
        viewedBucketListCountries = []
        relationshipState = .none

        Task {
            await load()
        }
    }

    // MARK: - Load
    func load() async {
        defer { isLoading = false }
        guard let userId else {
            print("⚠️ load() skipped — no userId yet")
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            profile = try await profileService.fetchOrCreateProfile(userId: userId)
            
            // 🔍 Load viewed user's stats (always by userId)
            viewedTraveledCountries = try await profileService.fetchTraveledCountries(userId: userId)
            viewedBucketListCountries = try await profileService.fetchBucketListCountries(userId: userId)
            
            print("📥 Loaded profile:", profile as Any)

            try await refreshRelationshipState()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Save (single source of truth)
    func saveProfile(
        firstName: String?,
        username: String?,
        homeCountries: [String]?,
        languages: [String]?,
        travelMode: String?,
        travelStyle: String?,
        avatarUrl: String?
    ) async {
        guard let userId else {
            print("⚠️ saveProfile() skipped — no userId")
            return
        }
        errorMessage = nil

        do {
            let payload = ProfileUpdate(
                username: username,
                fullName: firstName,
                avatarUrl: avatarUrl,
                languages: languages,
                livedCountries: homeCountries,
                travelStyle: travelStyle.map { [$0] },
                travelMode: travelMode.map { [$0] },
                onboardingCompleted: true
            )

            try await profileService.updateProfile(
                userId: userId,
                payload: payload
            )

            // 🔁 Re-fetch to guarantee consistency
            profile = try await profileService.fetchMyProfile(userId: userId)

            print("💾 Saved + reloaded profile:", profile as Any)

        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func uploadAvatar(data: Data, fileName: String) async throws -> String {
        let path = "\(fileName)"

        try await profileService.uploadAvatar(
            data: data,
            path: path
        )

        return try profileService.publicAvatarURL(path: path)
    }
    
    // MARK: - Relationship refresh

    private func refreshRelationshipState() async throws {
        guard
            let userId,
            let currentUserId = supabase.currentUserId
        else { return }

        // Viewing own profile
        if currentUserId == userId {
            relationshipState = .selfProfile
            isFriend = false
            return
        }

        // Friends?
        if try await supabase.isFriend(
            currentUserId: currentUserId,
            otherUserId: userId
        ) {
            relationshipState = .friends
            isFriend = true
            return
        }

        // Request already sent?
        if try await friendRequestsVM.hasSentRequest(to: userId) {
            relationshipState = .requestSent
            isFriend = false
            return
        }

        // No relationship
        relationshipState = .none
        isFriend = false
    }
    
    // MARK: - Friend actions

    func toggleFriend() async {
        guard let profileId = profile?.id else { return }

        isFriendLoading = true
        defer { isFriendLoading = false }

        do {
            switch relationshipState {
            case .none:
                do {
                    try await friendRequestsVM.sendFriendRequest(to: profileId)
                    print("📨 Friend request sent:", profileId)

                    // Optimistic UI update
                    relationshipState = .requestSent
                    isFriend = false
                } catch {
                    // Handle duplicate request (already sent)
                    if let pgError = error as? PostgrestError,
                       pgError.code == "23505" {
                        print("ℹ️ Friend request already exists — syncing state")

                        // Still reflect correct UI state
                        relationshipState = .requestSent
                        isFriend = false
                    } else {
                        throw error
                    }
                }

                // Refresh in background without breaking UI
                Task {
                    try? await refreshRelationshipState()
                }

            case .friends:
                try await supabase.removeFriend(friendId: profileId)
                try await refreshRelationshipState()
                print("➖ Removed friend:", profileId)

            case .requestSent:
                // No-op: request already sent
                print("ℹ️ Request already sent — no action")

            case .selfProfile:
                break
            }
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Relationship action failed:", error)
        }
    }
}
