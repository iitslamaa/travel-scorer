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
    private let profileService: ProfileService
    private let supabase = SupabaseManager.shared
    private let friendService = FriendService()
    private var userId: UUID?
    private var loadTask: Task<Void, Never>?
    private var loadGeneration: UUID = UUID()
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
    
    // MARK: - Load
    func load(generation: UUID) async {
        guard let userId else { return }

        isLoading = true
        defer { isLoading = false }
        errorMessage = nil
        isRelationshipLoading = true

        do {
            profile = try await profileService.fetchOrCreateProfile(userId: userId)
            friends = try await friendService.fetchFriends(for: userId)
            friendCount = friends.count
            // 👀 friends loaded and profile fetched
            // print("👀 friends loaded:", friends)
            // print("✅ profile fetched:", profile as Any)
            // print("➡️ fullName:", profile?.fullName as Any)
            // print("➡️ username:", profile?.username as Any)

            guard generation == loadGeneration else { return }

            viewedTraveledCountries =
                try await profileService.fetchTraveledCountries(userId: userId)
            viewedBucketListCountries =
                try await profileService.fetchBucketListCountries(userId: userId)

            guard generation == loadGeneration else { return }

            // Compute mutual bucket list if viewing someone else's profile
            if let currentUserId = supabase.currentUserId,
               currentUserId != userId {

                let currentUserBucket =
                    try await profileService.fetchBucketListCountries(userId: currentUserId)

                let currentSet = Set(currentUserBucket)
                let viewedSet = viewedBucketListCountries

                mutualBucketCountries = Array(currentSet.intersection(viewedSet)).sorted()

                // Compute mutual traveled countries
                let currentUserTraveled =
                    try await profileService.fetchTraveledCountries(userId: currentUserId)

                let currentTraveledSet = Set(currentUserTraveled)
                let viewedTraveledSet = viewedTraveledCountries

                mutualTraveledCountries =
                    Array(currentTraveledSet.intersection(viewedTraveledSet)).sorted()
            } else {
                mutualBucketCountries = []
                mutualTraveledCountries = []
            }

            computeOrderedLists()

            guard generation == loadGeneration else { return }

            isRelationshipLoading = true
            try await refreshRelationshipState()

            guard generation == loadGeneration else { return }

            await loadPendingRequestCount()

            guard generation == loadGeneration else { return }

            await loadMutualFriends()

        } catch {
            print("❌ load() failed:", error)
            errorMessage = error.localizedDescription
        }
    }
    
    func refreshProfile() async {
        let generation = UUID()
        loadGeneration = generation
        loadTask?.cancel()
        loadTask = Task { [weak self] in
            await self?.load(generation: generation)
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
        nextDestination: String?,
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
                nextDestination: nextDestination,
                onboardingCompleted: true
            )
            
            try await profileService.updateProfile(
                userId: userId,
                payload: payload
            )
            
            // 🔁 Reload full profile state (profile + traveled + bucket + mutuals)
            await refreshProfile()

            print("💾 Saved + fully reloaded profile state")
            
        } catch {
            errorMessage = error.localizedDescription
            print("❌ saveProfile failed:", error)
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
    
    func refreshRelationshipState() async throws {
        isRelationshipLoading = true
        guard
            let userId,
            let currentUserId = supabase.currentUserId
        else {
            isRelationshipLoading = false
            return
        }
        
        // Viewing own profile
        if currentUserId == userId {
            relationshipState = .selfProfile
            isFriend = false
            isRelationshipLoading = false
            return
        }
        
        // Friends?
        if try await friendService.isFriend(
            currentUserId: currentUserId,
            otherUserId: userId
        ) {
            relationshipState = .friends
            isFriend = true
            isRelationshipLoading = false
            return
        }
        
        // Request already sent?
        if try await friendService.hasSentRequest(from: currentUserId, to: userId) {
            relationshipState = .requestSent
            isFriend = false
            isRelationshipLoading = false
            return
        }
        
        // No relationship
        relationshipState = .none
        isFriend = false
        isRelationshipLoading = false
    }
    
    // MARK: - Friend Count
    
    func loadFriendCount() async {
        guard let userId else { return }
        
        do {
            let friends = try await friendService.fetchFriends(for: userId)
            friendCount = friends.count
        } catch {
            print("❌ failed to load friend count:", error)
            friendCount = 0
        }
    }

    // MARK: - Pending Friend Request Count

    func loadPendingRequestCount() async {
        guard let userId else { return }

        do {
            pendingRequestCount = try await friendService.fetchPendingRequestCount(for: userId)
            print("🔔 Pending requests:", pendingRequestCount)
        } catch {
            print("❌ failed to load pending request count:", error)
            pendingRequestCount = 0
        }
    }

    // MARK: - Mutual Friends

    func loadMutualFriends() async {
        guard
            let viewedUserId = userId,
            let currentUserId = supabase.currentUserId,
            currentUserId != viewedUserId
        else {
            mutualFriends = []
            return
        }

        do {
            mutualFriends = try await friendService.fetchMutualFriends(
                currentUserId: currentUserId,
                otherUserId: viewedUserId
            )
        } catch {
            print("❌ failed to load mutual friends:", error)
            mutualFriends = []
        }
    }
    
    // MARK: - Friend actions
    
    func toggleFriend() async {
        guard let profileId = profile?.id else { return }
        
        isFriendLoading = true
        defer { isFriendLoading = false }
        
        do {
            guard let state = relationshipState else { return }
            switch state {
            case .none:
                do {
                    guard let currentUserId = supabase.currentUserId else { return }
                    try await friendService.sendFriendRequest(from: currentUserId, to: profileId)
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
                guard let currentUserId = supabase.currentUserId else { return }
                try await friendService.removeFriend(myUserId: currentUserId, otherUserId: profileId)
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

    func cancelFriendRequest() async {
        guard let profileId = profile?.id,
              let currentUserId = supabase.currentUserId else { return }

        do {
            try await friendService.cancelRequest(
                from: currentUserId,
                to: profileId
            )

            relationshipState = .none
            isFriend = false

            print("❌ Friend request cancelled:", profileId)
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Cancel request failed:", error)
        }
    }
    // MARK: - Bucket Toggle

    func toggleBucket(_ countryId: String) async {
        guard let currentUserId = supabase.currentUserId else {
            print("❌ toggleBucket: No current user")
            return
        }

        let wasInBucket = viewedBucketListCountries.contains(countryId)

        // Optimistic UI update
        if wasInBucket {
            viewedBucketListCountries.remove(countryId)
        } else {
            viewedBucketListCountries.insert(countryId)
        }

        computeOrderedLists()

        do {
            if wasInBucket {
                try await profileService.removeFromBucketList(
                    userId: currentUserId,
                    countryCode: countryId
                )
            } else {
                try await profileService.addToBucketList(
                    userId: currentUserId,
                    countryCode: countryId
                )
            }
        } catch {
            // Rollback if server write fails
            if wasInBucket {
                viewedBucketListCountries.insert(countryId)
            } else {
                viewedBucketListCountries.remove(countryId)
            }

            computeOrderedLists()

            print("❌ toggleBucket rolled back due to error:", error)
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Traveled Toggle

    func toggleTraveled(_ countryId: String) async {
        guard let currentUserId = userId else {
            print("❌ toggleTraveled: No bound userId")
            return
        }

        let wasVisited = viewedTraveledCountries.contains(countryId)

        // Optimistic UI update
        if wasVisited {
            viewedTraveledCountries.remove(countryId)
        } else {
            viewedTraveledCountries.insert(countryId)
        }

        computeOrderedLists()

        do {
            if wasVisited {
                try await supabase.client
                    .from("user_traveled")
                    .delete()
                    .eq("user_id", value: currentUserId.uuidString)
                    .eq("country_id", value: countryId)
                    .execute()
            } else {
                try await supabase.client
                    .from("user_traveled")
                    .insert([
                        "user_id": currentUserId.uuidString,
                        "country_id": countryId
                    ])
                    .execute()
            }
        } catch {
            // Rollback on failure
            if wasVisited {
                viewedTraveledCountries.insert(countryId)
            } else {
                viewedTraveledCountries.remove(countryId)
            }

            computeOrderedLists()

            print("❌ toggleTraveled rolled back due to error:", error)
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Mutual Bucket Logic
    
    func computeMutualBucketList(
        currentUserCountries: [String],
        viewedUserCountries: [String]
    ) {
        let currentSet = Set(currentUserCountries)
        let viewedSet = Set(viewedUserCountries)
        mutualBucketCountries = Array(currentSet.intersection(viewedSet)).sorted()
    }

    private func computeOrderedLists() {
        let mutualBucketSet = Set(mutualBucketCountries)
        orderedBucketListCountries = viewedBucketListCountries.sorted {
            let lhsIsMutual = mutualBucketSet.contains($0)
            let rhsIsMutual = mutualBucketSet.contains($1)

            if lhsIsMutual != rhsIsMutual {
                return lhsIsMutual
            }
            return $0 < $1
        }

        let mutualTraveledSet = Set(mutualTraveledCountries)
        orderedTraveledCountries = viewedTraveledCountries.sorted {
            let lhsIsMutual = mutualTraveledSet.contains($0)
            let rhsIsMutual = mutualTraveledSet.contains($1)

            if lhsIsMutual != rhsIsMutual {
                return lhsIsMutual
            }
            return $0 < $1
        }
    }
}
