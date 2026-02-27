//
//  ProfileViewModel+Load.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 2/19/26.
//

import Foundation

extension ProfileViewModel {

    // MARK: - Load

    func load(generation: UUID) async {
        let startingUserId = userId

        
        print("   generation:", generation)
        print("   current loadGeneration:", loadGeneration)
        print("   userId at start:", startingUserId)

        // Only show full-screen loading during initial load,
        // NOT during pull-to-refresh.
        if !isRefreshing {
            isLoading = true
        }
        defer {
            if !isRefreshing {
                isLoading = false
            }
        }
        errorMessage = nil

        do {
            let fetchedProfile =
                try await profileService.fetchOrCreateProfile(userId: startingUserId)

            guard generation == loadGeneration,
                  self.userId == startingUserId else {
                print("🛑 ABORT after fetchProfile (identity changed)")
                return
            }

            print("🟢 assigning profile id:", fetchedProfile.id)
            profile = fetchedProfile

            let fetchedFriends =
                try await friendService.fetchFriends(for: startingUserId)

            guard generation == loadGeneration,
                  self.userId == startingUserId else {
                print("🛑 ABORT after fetchFriends (identity changed)")
                return
            }

            friends = fetchedFriends
            friendCount = fetchedFriends.count

            let traveled =
                try await profileService.fetchTraveledCountries(userId: startingUserId)

            guard generation == loadGeneration,
                  self.userId == startingUserId else {
                print("🛑 ABORT after fetchTraveled (identity changed)")
                return
            }

            viewedTraveledCountries = traveled

            let bucket =
                try await profileService.fetchBucketListCountries(userId: startingUserId)

            guard generation == loadGeneration,
                  self.userId == startingUserId else {
                print("🛑 ABORT after fetchBucket (identity changed)")
                return
            }

            viewedBucketListCountries = bucket

            // Reset mutuals before computing
            mutualLanguages = []
            mutualBucketCountries = []
            mutualTraveledCountries = []

            computeOrderedLists()

            // If viewing a friend, compute mutual country intersections
            if startingUserId != supabase.currentUserId {
                if let currentUserId = supabase.currentUserId {
                    let myTraveled =
                        try await profileService.fetchTraveledCountries(userId: currentUserId)

                    let myBucket =
                        try await profileService.fetchBucketListCountries(userId: currentUserId)

                    let normalizedMyTraveled = Set(
                        myTraveled.map {
                            $0.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
                        }
                    )

                    let normalizedMyBucket = Set(
                        myBucket.map {
                            $0.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
                        }
                    )

                    let normalizedViewedTraveled = Set(
                        viewedTraveledCountries.map {
                            $0.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
                        }
                    )

                    let normalizedViewedBucket = Set(
                        viewedBucketListCountries.map {
                            $0.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
                        }
                    )

                    mutualTraveledCountries =
                        Array(normalizedMyTraveled.intersection(normalizedViewedTraveled))

                    mutualBucketCountries =
                        Array(normalizedMyBucket.intersection(normalizedViewedBucket))

                    // Compute mutual languages (canonical codes)
                    if let viewedLanguages = profile?.languages {
                        if let myProfile = try? await profileService.fetchOrCreateProfile(userId: currentUserId) {
                            let myLanguages = Set(myProfile.languages)
                            let normalizedViewedLanguages = Set(viewedLanguages)

                            mutualLanguages = Array(myLanguages.intersection(normalizedViewedLanguages))
                        }
                    }
                }
            }

            guard generation == loadGeneration,
                  self.userId == startingUserId else {
                print("🛑 ABORT after computeOrderedLists")
                return
            }

            isRelationshipLoading = true
            try await refreshRelationshipState()
            isRelationshipLoading = false

            guard generation == loadGeneration,
                  self.userId == startingUserId else {
                print("🛑 ABORT after refreshRelationshipState")
                return
            }

            await loadPendingRequestCount()

            guard generation == loadGeneration,
                  self.userId == startingUserId else {
                print("🛑 ABORT after loadPendingRequestCount")
                return
            }

            await loadMutualFriends()

            print("✅ load() COMPLETE — user:", startingUserId)

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
}
