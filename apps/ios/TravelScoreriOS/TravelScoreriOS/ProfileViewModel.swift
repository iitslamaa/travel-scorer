//
//  ProfileViewModel.swift
//  TravelScoreriOS
//


import Foundation
import Combine

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

            // 🔍 Load relationship state
            if let currentUserId = supabase.currentUserId {
                // Viewing own profile
                if currentUserId == userId {
                    relationshipState = .selfProfile
                    isFriend = false
                    return
                }

                // Already friends?
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
    
    // MARK: - Friend actions

    func toggleFriend() async {
        guard let profileId = profile?.id else { return }

        isFriendLoading = true
        defer { isFriendLoading = false }

        do {
            switch relationshipState {
            case .none:
                try await friendRequestsVM.sendFriendRequest(to: profileId)
                relationshipState = .requestSent
                print("📨 Friend request sent:", profileId)

            case .friends:
                try await supabase.removeFriend(friendId: profileId)
                relationshipState = .none
                isFriend = false
                print("➖ Removed friend:", profileId)

            default:
                break
            }
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Relationship action failed:", error)
        }
    }
}
