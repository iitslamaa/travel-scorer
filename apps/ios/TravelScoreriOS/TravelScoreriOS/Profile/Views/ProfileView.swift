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
    @State private var headerMinY: CGFloat = 0

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
    
    private var miniAvatar: some View {
        Group {
            if let urlString = profileVM.profile?.avatarUrl,
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

                        GeometryReader { geo in
                            Color.clear
                                .onChange(of: geo.frame(in: .global).minY) { newValue in
                                    headerMinY = newValue
                                }
                        }
                        .frame(height: 0)

                        ProfileHeaderView(
                            profile: profileVM.profile,
                            username: username,
                            homeCountryCodes: homeCountryCodes,
                            relationshipState: profileVM.relationshipState,
                            friendCount: profileVM.friendCount,
                            userId: userId,
                            buttonTitle: buttonTitle,
                            headerMinY: headerMinY,
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
                .overlay(alignment: .top) {
                    let progress = min(max((165 - headerMinY) / 80, 0), 1)

                    HStack(spacing: 10) {
                        miniAvatar
                            .frame(width: 34, height: 34)
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 1) {
                            Text(profileVM.profile?.fullName ?? "")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .lineLimit(1)

                            if !username.isEmpty {
                                Text("@\(username)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: .black.opacity(0.08), radius: 10, y: 6)
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
                    .opacity(progress)
                    .animation(.easeInOut(duration: 0.18), value: progress)
                }
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
