//
//  ProfileHeaderView.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 2/13/26.
//

import Foundation
import SwiftUI

struct ProfileHeaderView: View {
    
    let profile: Profile?
    let username: String
    let homeCountryCodes: [String]
    let mutualFriends: [Profile]
    let onCancelRequest: () async -> Void
    let relationshipState: RelationshipState
    let friendCount: Int
    let userId: UUID
    let buttonTitle: String
    let headerMinY: CGFloat
    let onToggleFriend: () async -> Void
    
    @State private var isUnfriendAlertPresented = false
    @State private var showFriendDrawer = false
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        let pull = max(headerMinY - 165, 0)
        let cappedPull = min(pull, 120)

        let baseHeight: CGFloat = 180
        let dynamicHeight = baseHeight + cappedPull

        VStack {

            HStack(alignment: .center, spacing: 20 + cappedPull * 0.05) {

                avatarView
                    .frame(
                        width: 120 + cappedPull * 0.30,
                        height: 120 + cappedPull * 0.30
                    )
                    .shadow(
                        color: .black.opacity(0.18 + cappedPull * 0.001),
                        radius: 12 + cappedPull * 0.08,
                        y: 6 + cappedPull * 0.04
                    )
                    .animation(.spring(response: 0.4, dampingFraction: 0.85), value: cappedPull)

                profileTextContent
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .offset(y: -cappedPull * 0.08)
                    .scaleEffect(1 + cappedPull / 900)
                    .animation(.spring(response: 0.4, dampingFraction: 0.9), value: cappedPull)

            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16 + cappedPull * 0.08)

        }
        .frame(height: dynamicHeight)
        .background(Color(.systemBackground))
    }
    
    private var avatarView: some View {
        Group {
            if let urlString = profile?.avatarUrl,
               let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFill()
                    } else {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .scaledToFill()
                            .foregroundStyle(.gray)
                    }
                }
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .scaledToFill()
                    .foregroundStyle(.gray)
            }
        }
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(Color.white.opacity(0.9), lineWidth: 3)
        )
        .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
    }
    
    private var profileTextContent: some View {
        VStack(alignment: .leading, spacing: 6) {
            
            HStack(spacing: 6) {
                Text(profile?.fullName ?? "")
                    .font(.title2)
                    .fontWeight(.bold)
                
                if !username.isEmpty {
                    Text("(@\(username))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            if !homeCountryCodes.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(homeCountryCodes, id: \.self) { code in
                            Text(flagEmoji(for: code))
                                .font(.title3)
                        }
                    }
                }
                .padding(.top, 4)
            }
            
            if relationshipState != .selfProfile {
                headerFriendCTA
            }
        }
    }
    
    private var isFriends: Bool {
        relationshipState == .friends
    }

    private var headerFriendCTA: some View {
        Button {
            showFriendDrawer = true
        } label: {
            ZStack(alignment: .leading) {

                mutualFriendsFan
                    .offset(x: 4)
                    .opacity(mutualFriends.isEmpty ? 0 : 1)

                HStack(spacing: 6) {
                    if isFriends {
                        Image(systemName: "checkmark")
                            .font(.caption.weight(.bold))
                    }

                    Text(friendButtonLabel)
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .padding(.leading, mutualFriends.isEmpty ? 12 : 54)
                .padding(.trailing, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.blue.opacity(isFriends ? 0.16 : 0.10))
                )
                .overlay(
                    Capsule()
                        .stroke(Color.blue, lineWidth: isFriends ? 1.6 : 1.2)
                )
            }
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showFriendDrawer) {
            friendDrawer
                .presentationDetents([.medium])
        }
        .alert("Unfriend?", isPresented: $isUnfriendAlertPresented) {
            Button("Cancel", role: .cancel) {}
            Button("Confirm", role: .destructive) {
                Task { await onToggleFriend() }
            }
        }
    }

    private var mutualFriendsFan: some View {
        let shown = Array(mutualFriends.prefix(3))
        return ZStack {
            ForEach(Array(shown.enumerated()), id: \.element.id) { index, friend in
                mutualAvatar(urlString: friend.avatarUrl)
                    .frame(width: 28, height: 28)
                    .offset(x: CGFloat(index) * 14)
                    .zIndex(Double(10 - index))
            }
        }
    }

    private func mutualAvatar(urlString: String?) -> some View {
        Group {
            if let urlString, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFill()
                    } else {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .scaledToFill()
                            .foregroundStyle(.gray)
                    }
                }
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .scaledToFill()
                    .foregroundStyle(.gray)
            }
        }
        .clipShape(Circle())
        .overlay(Circle().stroke(Color(.systemBackground), lineWidth: 2))
        .shadow(color: .black.opacity(0.10), radius: 4, y: 2)
    }

    private var friendDrawer: some View {
        NavigationStack {
            VStack(spacing: 16) {

                NavigationLink {
                    FriendsView(userId: userId)
                } label: {
                    HStack {
                        Text("View \(firstName)’s friends")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }

                if relationshipState == .none {
                    Button {
                        Task { await onToggleFriend() }
                    } label: {
                        Text("Add Friend")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                }

                if relationshipState == .requestSent {
                    Button(role: .destructive) {
                        Task { await onCancelRequest() }
                    } label: {
                        Text("Cancel Friend Request")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }

                if relationshipState == .friends {
                    Button(role: .destructive) {
                        isUnfriendAlertPresented = true
                    } label: {
                        Text("Unfriend")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Friends")
        }
    }

    private var firstName: String {
        let raw = (profile?.fullName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if raw.isEmpty { return "their" }
        return raw.split(separator: " ").first.map(String.init) ?? "their"
    }
    
    private var friendButtonLabel: String {
        switch relationshipState {
        case .friends:
            if friendCount == 1 {
                return "1 Friend"
            } else {
                return "\(friendCount) Friends"
            }
        case .none:
            return "Add Friend"
        case .requestSent:
            return "Request Sent"
        case .selfProfile:
            return ""
        }
    }
    
    private func flagEmoji(for countryCode: String) -> String {
        countryCode
            .uppercased()
            .unicodeScalars
            .compactMap { UnicodeScalar(127397 + $0.value) }
            .map { String($0) }
            .joined()
    }
}
