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
    let relationshipState: RelationshipState
    let friendCount: Int
    let userId: UUID
    let buttonTitle: String
    let onToggleFriend: () async -> Void

    @State private var isUnfriendAlertPresented = false
    @State private var selectedCountryISO: String? = nil

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        GeometryReader { geo in
            let minY = geo.frame(in: .global).minY
            let pull = max(minY, 0)

            let baseHeight: CGFloat = 220
            let dynamicHeight = baseHeight + pull

            VStack {
                Spacer()

                HStack(alignment: .center, spacing: 18) {

                    avatarView
                        .frame(width: 120 + pull * 0.25,
                               height: 120 + pull * 0.25)
                        .animation(.spring(response: 0.35, dampingFraction: 0.8),
                                   value: pull)

                    profileTextContent
                        .scaleEffect(1 + pull / 600)
                        .animation(.spring(response: 0.35, dampingFraction: 0.8),
                                   value: pull)

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .frame(height: dynamicHeight)
            .background(Color(.systemBackground))
            .offset(y: pull > 0 ? -pull : 0)
        }
        .frame(height: 220)
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

            if friendCount > 0 {
                Text("\(friendCount) Friends")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }

            if relationshipState != .selfProfile {
                friendButton
            }
        }
    }

    private var friendButton: some View {
        Button {
            if relationshipState == .friends {
                isUnfriendAlertPresented = true
            } else {
                Task { await onToggleFriend() }
            }
        } label: {
            HStack(spacing: 6) {
                if relationshipState == .friends {
                    Image(systemName: "checkmark")
                }
                Text(buttonTitle)
            }
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
        .background(
            Capsule()
                .fill(relationshipState == .friends ? Color.green.opacity(0.15) : Color.blue.opacity(0.15))
        )
        .overlay(
            Capsule()
                .stroke(relationshipState == .friends ? Color.green : Color.blue, lineWidth: 1.5)
        )
        .alert("Unfriend?", isPresented: $isUnfriendAlertPresented) {
            Button("Cancel", role: .cancel) {}
            Button("Confirm", role: .destructive) {
                Task { await onToggleFriend() }
            }
        }
    }
}
