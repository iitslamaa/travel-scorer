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
    @Published var friendCount: Int = 0
    @Published var mutualBucketCountries: [String] = []
    @Published var mutualTraveledCountries: [String] = []
    @Published var pendingRequestCount: Int = 0
    
    // MARK: - Dependencies
    private let profileService: ProfileService
    private let supabase = SupabaseManager.shared
    private let friendService = FriendService()
    private var userId: UUID?
    
    // MARK: - Init
    init(profileService: ProfileService) {
        self.profileService = profileService
    }
    
    // MARK: - User binding
    
    func setUserIdIfNeeded(_ newUserId: UUID) {
        // 🔥 Prevent infinite rebinding loop
        guard userId != newUserId else { return }
        
        print("🔁 Binding profileVM to:", newUserId)
        
        userId = newUserId
        profile = nil
        errorMessage = nil
        viewedTraveledCountries = []
        viewedBucketListCountries = []
        mutualBucketCountries = []
        mutualTraveledCountries = []
        relationshipState = .none
        isFriend = false
        isFriendLoading = false
        
        Task {
            await load()
        }
    }
    
    // MARK: - Load
    func load() async {
        defer { isLoading = false }
        
        guard let userId else {
            print("❌ load() — userId is nil")
            return
        }
        
        print("🚀 load() called for userId:", userId)
        
        isLoading = true
        errorMessage = nil
        
        do {
            profile = try await profileService.fetchOrCreateProfile(userId: userId)
            
            print("✅ profile fetched:", profile as Any)
            print("➡️ fullName:", profile?.fullName as Any)
            print("➡️ username:", profile?.username as Any)
            
            viewedTraveledCountries =
            try await profileService.fetchTraveledCountries(userId: userId)
            
            viewedBucketListCountries =
            try await profileService.fetchBucketListCountries(userId: userId)
            
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
            
            try await refreshRelationshipState()
            await loadFriendCount()
            await loadPendingRequestCount()
            
        } catch {
            print("❌ load() failed:", error)
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
            
            // 🔁 Re-fetch profile row directly (avoid wiping with fetchOrCreateProfile)
            profile = try await profileService.fetchMyProfile(userId: userId)
            try await refreshRelationshipState()
            
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
    
    func refreshRelationshipState() async throws {
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
        if try await friendService.isFriend(
            currentUserId: currentUserId,
            otherUserId: userId
        ) {
            relationshipState = .friends
            isFriend = true
            return
        }
        
        // Request already sent?
        if try await friendService.hasSentRequest(from: currentUserId, to: userId) {
            relationshipState = .requestSent
            isFriend = false
            return
        }
        
        // No relationship
        relationshipState = .none
        isFriend = false
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
    
    // MARK: - Friend actions
    
    func toggleFriend() async {
        guard let profileId = profile?.id else { return }
        
        isFriendLoading = true
        defer { isFriendLoading = false }
        
        do {
            switch relationshipState {
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
    // MARK: - Mutual Bucket Logic
    
    func computeMutualBucketList(
        currentUserCountries: [String],
        viewedUserCountries: [String]
    ) {
        let currentSet = Set(currentUserCountries)
        let viewedSet = Set(viewedUserCountries)
        mutualBucketCountries = Array(currentSet.intersection(viewedSet)).sorted()
    }

    // MARK: - Ordered Bucket List (Mutuals First)

    var orderedBucketListCountries: [String] {
        let all = viewedBucketListCountries
        let mutualSet = Set(mutualBucketCountries)

        return all.sorted {
            let lhsIsMutual = mutualSet.contains($0)
            let rhsIsMutual = mutualSet.contains($1)

            if lhsIsMutual != rhsIsMutual {
                return lhsIsMutual
            }

            return $0 < $1
        }
    }

    // MARK: - Ordered Traveled Countries (Mutuals First)

    var orderedTraveledCountries: [String] {
        let all = viewedTraveledCountries
        let mutualSet = Set(mutualTraveledCountries)

        return all.sorted {
            let lhsIsMutual = mutualSet.contains($0)
            let rhsIsMutual = mutualSet.contains($1)

            if lhsIsMutual != rhsIsMutual {
                return lhsIsMutual
            }

            return $0 < $1
        }
    }
}
