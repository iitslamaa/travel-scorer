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
    @State private var isPressed = false
    
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
                        color: Color.primary.opacity(0.14 + cappedPull * 0.001),
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
                .stroke(Color(.systemBackground), lineWidth: 3)
        )
        .shadow(color: Color.primary.opacity(0.12), radius: 12, y: 6)
    }
    
    private var profileTextContent: some View {
        VStack(alignment: .leading, spacing: 6) {
            
            VStack(alignment: .leading, spacing: 2) {
                Text(profile?.fullName ?? "")
                    .font(.title2)
                    .fontWeight(.bold)

                if !username.isEmpty {
                    Text("@\(username)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
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
        .shadow(color: Color.primary.opacity(0.08), radius: 4, y: 2)
    }

    private var friendDrawer: some View {
        NavigationStack {
            VStack(spacing: 16) {

                NavigationLink {
                    FriendsView(userId: userId)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.blue)
                            .frame(width: 36, height: 36)
                            .background(
                                Circle()
                                    .fill(Color.blue.opacity(0.12))
                            )

                        Text("View \(firstName)’s friends")
                            .font(.headline)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(.ultraThinMaterial)
                    )
                }

                if relationshipState == .none {
                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        Task { await onToggleFriend() }
                    } label: {
                        HStack {
                            Image(systemName: "person.badge.plus")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Add Friend")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.blue)
                        )
                        .foregroundStyle(.white)
                    }
                    .scaleEffect(isPressed ? 0.94 : 1.0)
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in isPressed = true }
                            .onEnded { _ in isPressed = false }
                    )
                    .animation(.easeOut(duration: 0.15), value: isPressed)
                }

                if relationshipState == .requestSent {
                    Button(role: .destructive) {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        Task { await onCancelRequest() }
                    } label: {
                        HStack {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Cancel Friend Request")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.red.opacity(0.12))
                        )
                        .foregroundStyle(.red)
                    }
                    .buttonStyle(PressableScaleStyle())
                }

                if relationshipState == .friends {
                    Button(role: .destructive) {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        isUnfriendAlertPresented = true
                    } label: {
                        HStack {
                            Image(systemName: "person.crop.circle.badge.minus")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Unfriend")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.red.opacity(0.14))
                        )
                        .foregroundStyle(.red)
                    }
                    .buttonStyle(PressableScaleStyle())
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
    
    private struct PressableScaleStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
                .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
        }
    }
}
