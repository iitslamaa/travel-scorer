//
//  ProfileViewModel+Friends.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 2/19/26.
//

import Foundation
import Combine
import Supabase
import PostgREST

extension ProfileViewModel {

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
}
