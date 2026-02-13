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
                        stretchyHeader

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
    private var stretchyHeader: some View {
        GeometryReader { geo in
            let minY = geo.frame(in: .named("SCROLL")).minY
            let pull = max(minY, 0)

            // Base header height
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
            .background(
                Color(.systemBackground)
                    .shadow(color: .black.opacity(0.06),
                            radius: pull > 0 ? 0 : 8,
                            y: 6)
            )
            .offset(y: pull > 0 ? -pull : 0)
        }
        .frame(height: 220)
    }


    private var avatarView: some View {
        Group {
            if let urlString = profileVM.profile?.avatarUrl,
               let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .scaledToFill()
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
        .frame(width: 120, height: 120)
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(Color.white.opacity(0.9), lineWidth: 3)
        )
        .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
        .layoutPriority(1)
    }

    private var profileTextContent: some View {
        VStack(alignment: .leading, spacing: 6) {

            HStack(spacing: 6) {
                Text(profileVM.profile?.fullName ?? "")
                    .font(.title2)
                    .fontWeight(.bold)

                if !username.isEmpty {
                    Text("(@\(username))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            FlagStrip(
                flags: flags(for: Set(homeCountryCodes)),
                fontSize: 26,
                spacing: 6,
                showsTooltip: true
            )

            if profileVM.friendCount > 0 {
                NavigationLink {
                    FriendsView(userId: userId)
                } label: {
                    Text("\(profileVM.friendCount) Friends")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.blue)
                }
            }

            if profileVM.relationshipState != .selfProfile {
                friendButton
            }
        }
    }

    private var friendButton: some View {
        Button {
            if profileVM.relationshipState == .friends {
                showUnfriendConfirmation = true
            } else {
                Task { await profileVM.toggleFriend() }
            }
        } label: {
            HStack(spacing: 6) {
                if profileVM.relationshipState == .friends {
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
                .fill(profileVM.relationshipState == .friends ? Color.green.opacity(0.15) : Color.blue.opacity(0.15))
        )
        .overlay(
            Capsule()
                .stroke(profileVM.relationshipState == .friends ? Color.green : Color.blue, lineWidth: 1.5)
        )
        .disabled(profileVM.relationshipState == .requestSent)
        .alert("Unfriend?", isPresented: $showUnfriendConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Confirm", role: .destructive) {
                Task { await profileVM.toggleFriend() }
            }
        } message: {
            Text("Are you sure you want to remove this friend?")
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


