//
//  ProfileView.swift
//  TravelScoreriOS
//

import SwiftUI

extension Color {
    static let gold = Color(red: 0.85, green: 0.68, blue: 0.15)
}

extension Notification.Name {
    static let friendshipUpdated = Notification.Name("friendshipUpdated")
}

struct ProfileView: View {
    @EnvironmentObject private var sessionManager: SessionManager
    @EnvironmentObject private var bucketList: BucketListStore
    @EnvironmentObject private var traveled: TraveledStore
    @EnvironmentObject private var profileVM: ProfileViewModel
    @Environment(\.colorScheme) private var colorScheme

    private let userId: UUID
    @State private var showUnfriendConfirmation = false

    init(userId: UUID) {
        self.userId = userId
    }

    private var username: String { profileVM.profile?.username ?? "" }
    private var homeCountryCodes: [String] { profileVM.profile?.livedCountries ?? [] }
    private var languages: [String] { profileVM.profile?.languages ?? [] }

    private var buttonTitle: String {
        switch profileVM.relationshipState {
        case .none:
            return "Add Friend"
        case .requestSent:
            return "Request Sent"
        case .friends:
            return "Friends"
        case .selfProfile:
            return ""
        }
    }
    
    private var firstName: String {
        let raw = (profileVM.profile?.fullName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if raw.isEmpty { return "Profile" }
        return raw.split(separator: " ").first.map(String.init) ?? "Profile"
    }

    private var navigationTitle: String {
        "\(firstName)’s Profile"
    }

    var body: some View {
        ZStack {
            // Premium clean native background
            Color(.systemBackground)
                .ignoresSafeArea()

            if profileVM.isLoading && profileVM.profile == nil {
                ProgressView("Loading profile…")
            } else {
                ScrollView {
                    VStack(spacing: 0) {

                        // Stretchy header should NOT be padded horizontally
                        ProfileHeaderView(
                            profile: profileVM.profile,
                            username: username,
                            relationshipState: profileVM.relationshipState,
                            friendCount: profileVM.friendCount,
                            userId: userId,
                            buttonTitle: buttonTitle,
                            onToggleFriend: {
                                await profileVM.toggleFriend()
                            }
                        )

                        VStack(spacing: 28) {
                            languagesCard
                            infoCards
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 28)
                        .padding(.bottom, 32)
                    }
                }
                .coordinateSpace(name: "SCROLL")
                .scrollIndicators(.hidden)
                .scrollBounceBehavior(.basedOnSize)
            }
        }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            if SupabaseManager.shared.currentUserId == userId {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        ProfileSettingsView(
                            profileVM: profileVM,
                            viewedUserId: userId
                        )
                    } label: {
                        Image(systemName: "gearshape")
                            .symbolRenderingMode(.hierarchical)
                            .font(.system(size: 18, weight: .semibold))
                    }
                }
            }
        }
        .onAppear {
            profileVM.setUserIdIfNeeded(userId)
            Task { try? await profileVM.refreshRelationshipState() }
        }
    }
  
    private var infoCards: some View {
        VStack(spacing: 12) {
            if profileVM.relationshipState == .selfProfile {

                CollapsibleCountrySection(
                    title: "Countries Traveled",
                    countryCodes: flags(for: profileVM.viewedTraveledCountries),
                    highlightColor: .gold
                )

                CollapsibleCountrySection(
                    title: "Want to Visit",
                    countryCodes: flags(for: profileVM.viewedBucketListCountries),
                    highlightColor: .blue
                )

            } else if profileVM.relationshipState == .friends {

                CollapsibleCountrySection(
                    title: "Countries Traveled",
                    countryCodes: profileVM.orderedTraveledCountries,
                    highlightColor: .gold,
                    mutualCountries: Set(profileVM.mutualTraveledCountries)
                )

                CollapsibleCountrySection(
                    title: "Want to Visit",
                    countryCodes: profileVM.orderedBucketListCountries,
                    highlightColor: .blue,
                    mutualCountries: Set(profileVM.mutualBucketCountries)
                )

            } else {
                lockedProfileMessage
            }
        }
    }

    private var languagesCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Languages")
                .font(.subheadline)
                .fontWeight(.semibold)

            if languages.isEmpty {
                Text("Not set")
                    .font(.caption)
                    .foregroundStyle(.black.opacity(0.6))
            } else {
                Text(languages.joined(separator: " · "))
                    .font(.subheadline)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(colorScheme == .dark ? .ultraThinMaterial : .regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
    }

    private var lockedProfileMessage: some View {
        VStack(spacing: 8) {
            Image(systemName: "lock.fill")
                .font(.title2)
                .foregroundColor(.secondary)

            Text("Learn more about this user by adding them as a friend!")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .background(colorScheme == .dark ? .ultraThinMaterial : .regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
    }

    private func flags(for ids: Set<String>) -> [String] {
        ids.map { $0.uppercased() }.sorted()
    }
}


