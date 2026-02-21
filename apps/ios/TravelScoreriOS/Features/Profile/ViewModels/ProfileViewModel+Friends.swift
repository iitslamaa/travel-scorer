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
        let userId = self.userId
        print("👥 loadFriendCount for:", userId)
        
        do {
            let friends = try await friendService.fetchFriends(for: userId)
            print("   👥 fetched friends count:", friends.count)
            friendCount = friends.count
            print("   👥 assigned friendCount:", friendCount)
        } catch {
            print("❌ failed to load friend count:", error)
            friendCount = 0
        }
    }

    // MARK: - Pending Friend Request Count

    func loadPendingRequestCount() async {
        let userId = self.userId
        print("🔔 loadPendingRequestCount for:", userId)

        do {
            pendingRequestCount = try await friendService.fetchPendingRequestCount(for: userId)
            print("   🔔 assigned pendingRequestCount:", pendingRequestCount)
        } catch {
            print("❌ failed to load pending request count:", error)
            pendingRequestCount = 0
        }
    }

    // MARK: - Mutual Friends

    func loadMutualFriends() async {
        let viewedUserId = self.userId
        guard
            let currentUserId = supabase.currentUserId,
            currentUserId != viewedUserId
        else {
            print("   🤝 no mutual friends context, clearing mutualFriends")
            mutualFriends = []
            return
        }

        print("🤝 loadMutualFriends for viewedUserId:", viewedUserId)
        print("🤝 currentUserId:", currentUserId)
        do {
            print("   🤝 fetching mutual friends...")
            mutualFriends = try await friendService.fetchMutualFriends(
                currentUserId: currentUserId,
                otherUserId: viewedUserId
            )
            print("   🤝 assigned mutualFriends count:", mutualFriends.count)
        } catch {
            print("❌ failed to load mutual friends:", error)
            mutualFriends = []
        }
    }
}
