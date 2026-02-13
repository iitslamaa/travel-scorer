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
    let relationshipState: RelationshipState
    let friendCount: Int
    let userId: UUID
    let buttonTitle: String
    let headerMinY: CGFloat
    let onToggleFriend: () async -> Void
    
    @State private var isUnfriendAlertPresented = false
    @State private var selectedCountryISO: String? = nil
    
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
            
            if friendCount > 0 {
                Text("\(friendCount) Friends")
                    .font(.subheadline)
                    .fontWeight(.semibold)
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
    
    private func flagEmoji(for countryCode: String) -> String {
        countryCode
            .uppercased()
            .unicodeScalars
            .compactMap { UnicodeScalar(127397 + $0.value) }
            .map { String($0) }
            .joined()
    }
}
