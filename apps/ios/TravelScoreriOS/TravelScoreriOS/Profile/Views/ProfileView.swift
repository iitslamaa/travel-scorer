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

                        ProfileInfoSection(
                            relationshipState: profileVM.relationshipState,
                            viewedTraveledCountries: profileVM.viewedTraveledCountries,
                            viewedBucketListCountries: profileVM.viewedBucketListCountries,
                            orderedTraveledCountries: profileVM.orderedTraveledCountries,
                            orderedBucketListCountries: profileVM.orderedBucketListCountries,
                            mutualTraveledCountries: profileVM.mutualTraveledCountries,
                            mutualBucketCountries: profileVM.mutualBucketCountries,
                            languages: languages
                        )
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
  
}
