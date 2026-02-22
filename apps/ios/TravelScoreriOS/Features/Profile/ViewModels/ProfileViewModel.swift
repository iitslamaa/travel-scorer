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
    
    let instanceId = UUID()
    
    // MARK: - Published state
    @Published var profile: Profile? {
        didSet {
            print("📦 [\(instanceId)] profile DID SET →", profile?.id as Any)
            logPublishedState("profile updated")
        }
    }
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isFriend: Bool = false
    @Published var isFriendLoading: Bool = false
    @Published var relationshipState: RelationshipState = .none
    @Published var isRelationshipLoading: Bool = false
    @Published var isRefreshing: Bool = false
    @Published var viewedTraveledCountries: Set<String> = [] {
        didSet {
            print("✈️ [\(instanceId)] traveled DID SET → count:", viewedTraveledCountries.count)
        }
    }
    @Published var viewedBucketListCountries: Set<String> = [] {
        didSet {
            print("🪣 [\(instanceId)] bucket DID SET → count:", viewedBucketListCountries.count)
        }
    }
    @Published var friendCount: Int = 0
    @Published var friends: [Profile] = [] {
        didSet {
            print("👥 [\(instanceId)] friends DID SET → count:", friends.count)
            logPublishedState("friends updated")
        }
    }
    @Published var mutualBucketCountries: [String] = []
    @Published var mutualTraveledCountries: [String] = []
    @Published var pendingRequestCount: Int = 0
    @Published var mutualFriends: [Profile] = []
    @Published var orderedBucketListCountries: [String] = [] {
        didSet {
            print("📊 [\(instanceId)] orderedBucket DID SET →", orderedBucketListCountries)
        }
    }
    @Published var orderedTraveledCountries: [String] = [] {
        didSet {
            print("📊 [\(instanceId)] orderedTraveled DID SET →", orderedTraveledCountries)
        }
    }
    
    // MARK: - Dependencies
    let profileService: ProfileService
    let friendService: FriendService
    let supabase = SupabaseManager.shared

    // ✅ Identity is now immutable (no rebinding)
    let userId: UUID

    var loadTask: Task<Void, Never>?
    var loadGeneration: UUID = UUID()
    
    // MARK: - Init
    init(
        userId: UUID,
        profileService: ProfileService,
        friendService: FriendService
    ) {
        print("🧠 ProfileViewModel INIT — instance:", instanceId)
        self.userId = userId
        self.profileService = profileService
        self.friendService = friendService
    }
    
    // MARK: - Pull to Refresh Support

    /// Forces a full reload even if the same user is already bound.
    /// This is used by `.refreshable` in ProfileView.
    func reloadProfile() async {
        print("🔄 [\(instanceId)] reloadProfile called for:", userId)

        isRefreshing = true
        errorMessage = nil

        cancelInFlightWork()

        let generation = UUID()
        loadGeneration = generation

        loadTask = Task { [weak self] in
            await self?.load(generation: generation)
        }

        await loadTask?.value

        isRefreshing = false
    }
    
    // MARK: - Identity-Safe Lifecycle

    func loadIfNeeded() async {
        guard profile?.id != userId else { return }

        isLoading = true
        errorMessage = nil
        isRelationshipLoading = true

        // 🔒 Reset visible state to prevent stale UI flash
        profile = nil
        relationshipState = .none
        friends = []
        viewedTraveledCountries = []
        viewedBucketListCountries = []
        orderedBucketListCountries = []
        orderedTraveledCountries = []
        mutualFriends = []
        mutualBucketCountries = []
        mutualTraveledCountries = []
        friendCount = 0

        cancelInFlightWork()

        let generation = UUID()
        loadGeneration = generation

        loadTask = Task { [weak self] in
            await self?.load(generation: generation)
        }

        await loadTask?.value
        isRelationshipLoading = false
        isLoading = false
    }

    func cancelInFlightWork() {
        loadTask?.cancel()
        loadTask = nil
    }
    
    deinit {
        print("💀 ProfileViewModel DEINIT — instance:", instanceId, "userId:", userId as Any)
    }
    
    func logPublishedState(_ label: String) {
        print("📡 [\(instanceId)] \(label)")
        print("   userId:", userId)
        print("   profile.id:", profile?.id as Any)
        print("   friends.count:", friends.count)
        print("   traveled.count:", viewedTraveledCountries.count)
        print("   bucket.count:", viewedBucketListCountries.count)
        print("   relationshipState:", relationshipState as Any)
    }
}
