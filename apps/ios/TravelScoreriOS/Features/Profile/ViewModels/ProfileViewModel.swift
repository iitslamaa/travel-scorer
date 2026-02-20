//
//  ProfileViewModel.swift
//  TravelScoreriOS
//


import Foundation
import Combine
import PostgREST
import Supabase

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
    @Published var relationshipState: RelationshipState? = nil
    @Published var isRelationshipLoading: Bool = false
    @Published var viewedTraveledCountries: Set<String> = []
    @Published var viewedBucketListCountries: Set<String> = []
    @Published var friendCount: Int = 0
    @Published var friends: [Profile] = []
    @Published var mutualBucketCountries: [String] = []
    @Published var mutualTraveledCountries: [String] = []
    @Published var pendingRequestCount: Int = 0
    @Published var mutualFriends: [Profile] = []
    @Published var orderedBucketListCountries: [String] = []
    @Published var orderedTraveledCountries: [String] = []
    
    // MARK: - Dependencies
    let profileService: ProfileService
    let supabase = SupabaseManager.shared
    let friendService = FriendService()
    var userId: UUID?
    var loadTask: Task<Void, Never>?
    var loadGeneration: UUID = UUID()
    @Published private(set) var boundUserId: UUID?
    
    // MARK: - Init
    init(profileService: ProfileService) {
        self.profileService = profileService
    }
    
    // MARK: - User binding
    
    func setUserIdIfNeeded(_ newUserId: UUID) {
        guard userId != newUserId else { return }

        userId = newUserId
        boundUserId = newUserId

        profile = nil
        errorMessage = nil
        viewedTraveledCountries = []
        viewedBucketListCountries = []
        mutualBucketCountries = []
        mutualTraveledCountries = []
        friends = []
        mutualFriends = []
        relationshipState = nil
        isRelationshipLoading = true
        isFriend = false
        isFriendLoading = false
        friendCount = 0

        loadTask?.cancel()

        let generation = UUID()
        loadGeneration = generation

        loadTask = Task { [weak self] in
            await self?.load(generation: generation)
        }
    }
    
    // MARK: - Pull to Refresh Support

    /// Forces a full reload even if the same user is already bound.
    /// This is used by `.refreshable` in ProfileView.
    func reloadProfile(userId: UUID) async {
        self.userId = userId
        boundUserId = userId

        isLoading = true
        errorMessage = nil
        isRelationshipLoading = true

        loadTask?.cancel()

        let generation = UUID()
        loadGeneration = generation

        loadTask = Task { [weak self] in
            await self?.load(generation: generation)
        }

        await loadTask?.value

        isLoading = false
    }
}
