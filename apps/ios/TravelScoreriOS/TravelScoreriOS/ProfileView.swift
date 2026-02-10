//
//  ProfileView.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 2/6/26.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var sessionManager: SessionManager
    @EnvironmentObject private var bucketList: BucketListStore
    @EnvironmentObject private var traveled: TraveledStore

    @StateObject private var profileVM: ProfileViewModel
    private let userId: UUID

    init(userId: UUID) {
        self.userId = userId
        _profileVM = StateObject(
            wrappedValue: ProfileViewModel(
                profileService: ProfileService(supabase: SupabaseManager.shared)
            )
        )
    }

    // Computed properties bound to profileVM.profile
    private var username: String { profileVM.profile?.username ?? "" }
    private var travelMode: String? { profileVM.profile?.travelMode.first }
    private var travelStyle: String? { profileVM.profile?.travelStyle.first }
    private var homeCountryCodes: [String] { profileVM.profile?.livedCountries ?? [] }
    private var languages: [String] { profileVM.profile?.languages ?? [] }

    var body: some View {
        ZStack {
            // Background image
            Image("profile_background")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            // Subtle overlay for readability (keeps clouds visible)
            LinearGradient(
                colors: [
                    Color.white.opacity(0.12),
                    Color.white.opacity(0.30),
                    Color.white.opacity(0.12)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            if profileVM.isLoading && profileVM.profile == nil {
                ProgressView("Loading profile…")
            } else {
                ScrollView {
                    VStack(spacing: 24) {

                        profileHeader

                        languagesCard

                        infoCards
                    }
                    .padding()
                }
            }
        }
        .foregroundStyle(.black)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink {
                    ProfileSettingsView(profileVM: profileVM)
                } label: {
                    Image(systemName: "gearshape")
                }
            }
        }
        .task {
            profileVM.setUserIdIfNeeded(userId)
        }
    }

    private var profileHeader: some View {
        HStack(alignment: .center, spacing: 16) {

            // Large profile image on the left
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
                                .foregroundStyle(.gray)
                        }
                    }
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .foregroundStyle(.gray)
                }
            }
            .frame(width: 110, height: 110)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 8) {

                // Name + username inline
                HStack(spacing: 6) {
                    Text(profileVM.profile?.fullName ?? "")
                        .font(.title2)
                        .fontWeight(.bold)

                    if !username.isEmpty {
                        Text("(@\(username))")
                            .font(.subheadline)
                            .foregroundStyle(.black.opacity(0.6))
                    }
                }

                // Home countries under name
                FlagStrip(
                    flags: flags(for: Set(homeCountryCodes)),
                    fontSize: 28,
                    spacing: 6
                )

                // Relationship action button
                if profileVM.relationshipState != .selfProfile {
                    Button {
                        Task {
                            await profileVM.toggleFriend()
                        }
                    } label: {
                        if profileVM.isFriendLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            switch profileVM.relationshipState {
                            case .none:
                                Text("Add Friend")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)

                            case .requestSent:
                                Text("Request Sent")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)

                            case .friends:
                                Text("Friends ✓")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)

                            case .selfProfile:
                                EmptyView()
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.08))
                    )
                    .disabled(
                        profileVM.isFriendLoading ||
                        profileVM.relationshipState == .requestSent
                    )
                }
            }

            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private var infoCards: some View {
        VStack(spacing: 12) {

            if profileVM.relationshipState == .selfProfile ||
               profileVM.relationshipState == .friends {

                ProfileCard(
                    title: "Countries Traveled",
                    flags: flags(for: profileVM.viewedTraveledCountries)
                )

                ProfileCard(
                    title: "Want to Visit",
                    flags: flags(for: profileVM.viewedBucketListCountries)
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
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.75))
        )
    }

    private var travelModeDisplay: String? {
        guard let travelMode else { return nil }
        switch travelMode.lowercased() {
        case "solo": return "Solo"
        case "group": return "Group"
        case "solo + group": return "Solo + Group"
        default: return travelMode
        }
    }

    private var travelStyleDisplay: String? {
        guard let travelStyle else { return nil }
        switch travelStyle.lowercased() {
        case "budget": return "BUDGET"
        case "comfortable": return "COMFORTABLE"
        case "in-between": return "IN-between"
        case "both": return "Both on occasion"
        default: return travelStyle
        }
    }

    private var languagesDisplay: String? {
        guard !languages.isEmpty else { return nil }
        return languages.joined(separator: " · ")
    }


    private var lockedProfileMessage: some View {
        VStack(spacing: 8) {
            Image(systemName: "lock.fill")
                .font(.title2)
                .foregroundColor(.secondary)

            Text("Learn more about this user by adding them as a friend!")
                .font(.subheadline)
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.75))
        )
    }

    // MARK: - Helpers

    private func flags(for ids: Set<String>) -> [String] {
        ids
            .map { $0.uppercased() }
            .sorted()
            .map { countryCodeToFlag($0) }
    }

    private func countryCodeToFlag(_ code: String) -> String {
        guard code.count == 2 else { return code }
        let base: UInt32 = 127397
        return code.unicodeScalars
            .compactMap { UnicodeScalar(base + $0.value) }
            .map { String($0) }
            .joined()
    }
}

private struct ProfileCard: View {
    let title: String
    let flags: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {

            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer()

                Text("\(flags.count)")
                    .font(.caption)
                    .foregroundStyle(.black.opacity(0.6))
            }

            if flags.isEmpty {
                Text("None yet")
                    .font(.caption)
                    .foregroundStyle(.black.opacity(0.6))
                    .padding(.vertical, 4)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    FlagStrip(flags: flags, fontSize: 30, spacing: 10)
                        .padding(.vertical, 2)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.75))
        )
    }
}

private struct FlagStrip: View {
    let flags: [String]
    let fontSize: CGFloat
    let spacing: CGFloat

    var body: some View {
        LazyHStack(spacing: spacing) {
            ForEach(flags, id: \.self) { flag in
                Text(flag)
                    .font(.system(size: fontSize))
                    .fixedSize() // prevents emoji clipping
            }
        }
        .padding(.horizontal, 2)
    }
}
