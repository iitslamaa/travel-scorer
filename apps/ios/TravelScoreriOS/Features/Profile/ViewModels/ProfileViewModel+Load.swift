//
//  ProfileViewModel+Load.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 2/19/26.
//

import Foundation
import Combine
import Supabase
import PostgREST

extension ProfileViewModel {

    // MARK: - Load

    func load(generation: UUID) async {
        guard let userId else { return }

        isLoading = true
        defer { isLoading = false }
        errorMessage = nil

        do {
            profile = try await profileService.fetchOrCreateProfile(userId: userId)
            friends = try await friendService.fetchFriends(for: userId)
            friendCount = friends.count

            guard generation == loadGeneration else { return }

            viewedTraveledCountries =
                try await profileService.fetchTraveledCountries(userId: userId)
            viewedBucketListCountries =
                try await profileService.fetchBucketListCountries(userId: userId)

            guard generation == loadGeneration else { return }

            if let currentUserId = supabase.currentUserId,
               currentUserId != userId {

                let currentUserBucket =
                    try await profileService.fetchBucketListCountries(userId: currentUserId)

                let currentSet = Set(currentUserBucket)
                let viewedSet = viewedBucketListCountries

                mutualBucketCountries = Array(currentSet.intersection(viewedSet)).sorted()

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
}
