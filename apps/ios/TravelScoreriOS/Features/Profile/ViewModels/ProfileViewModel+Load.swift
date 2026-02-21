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

        print("🟣 load() START — instance:", instanceId)
        print("   generation:", generation)
        print("   current loadGeneration:", loadGeneration)
        print("   userId at start:", startingUserId)

        isLoading = true
        defer { isLoading = false }
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
            logPublishedState("after profile assignment")

            let fetchedFriends =
                try await friendService.fetchFriends(for: startingUserId)

            guard generation == loadGeneration,
                  self.userId == startingUserId else {
                print("🛑 ABORT after fetchFriends (identity changed)")
                return
            }

            friends = fetchedFriends
            friendCount = fetchedFriends.count
            logPublishedState("after friends assignment")

            let traveled =
                try await profileService.fetchTraveledCountries(userId: startingUserId)

            guard generation == loadGeneration,
                  self.userId == startingUserId else {
                print("🛑 ABORT after fetchTraveled (identity changed)")
                return
            }

            viewedTraveledCountries = traveled
            logPublishedState("after traveled assignment")

            let bucket =
                try await profileService.fetchBucketListCountries(userId: startingUserId)

            guard generation == loadGeneration,
                  self.userId == startingUserId else {
                print("🛑 ABORT after fetchBucket (identity changed)")
                return
            }

            viewedBucketListCountries = bucket
            logPublishedState("after bucket assignment")

            mutualBucketCountries = []
            mutualTraveledCountries = []

            computeOrderedLists()
            logPublishedState("after computeOrderedLists")

            guard generation == loadGeneration,
                  self.userId == startingUserId else {
                print("🛑 ABORT after computeOrderedLists")
                return
            }

            isRelationshipLoading = true
            try await refreshRelationshipState()
            logPublishedState("after refreshRelationshipState")

            guard generation == loadGeneration,
                  self.userId == startingUserId else {
                print("🛑 ABORT after refreshRelationshipState")
                return
            }

            await loadPendingRequestCount()
            logPublishedState("after loadPendingRequestCount")

            guard generation == loadGeneration,
                  self.userId == startingUserId else {
                print("🛑 ABORT after loadPendingRequestCount")
                return
            }

            await loadMutualFriends()
            logPublishedState("after loadMutualFriends")

            print("✅ load() COMPLETE — instance:", instanceId, "user:", startingUserId)
            logPublishedState("load complete")

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
