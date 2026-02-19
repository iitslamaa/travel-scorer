//
//  ProfileViewModel+Relationship.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 2/19/26.
//

import Foundation
import Combine
import Supabase
import PostgREST

extension ProfileViewModel {

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
}
