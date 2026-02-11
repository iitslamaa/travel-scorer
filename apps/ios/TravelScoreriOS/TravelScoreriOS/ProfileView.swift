//
//  ProfileView.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 2/6/26.
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
    private let userId: UUID

    @State private var showUnfriendConfirmation = false

    init(userId: UUID) {
        self.userId = userId
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
            if SupabaseManager.shared.currentUserId == userId {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        ProfileSettingsView(
                            profileVM: profileVM,
                            viewedUserId: userId
                        )
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
        }
        .onAppear {
            profileVM.setUserIdIfNeeded(userId)
        }
        .onReceive(NotificationCenter.default.publisher(for: .friendshipUpdated)) { _ in
            Task {
                await profileVM.loadFriendCount()
                try? await profileVM.refreshRelationshipState()
            }
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

            VStack(alignment: .leading, spacing: 4) {

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
                                Text("Unfriend")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .onTapGesture {
                                        showUnfriendConfirmation = true
                                    }

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
                    .alert("Unfriend this user?", isPresented: $showUnfriendConfirmation) {
                        Button("Unfriend", role: .destructive) {
                            Task {
                                await profileVM.toggleFriend()
                            }
                        }
                        Button("Cancel", role: .cancel) { }
                    }
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

private struct CollapsibleCountrySection: View {
    let title: String
    let countryCodes: [String]
    let highlightColor: Color

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .foregroundColor(.black)
                        .padding(.trailing, 2)

                    Text("\(title): ")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text("#\(countryCodes.count)")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(highlightColor)

                    Spacer()
                }
            }

            if isExpanded {
                VStack(spacing: 16) {

                    // Flags
                    if countryCodes.isEmpty {
                        Text("None yet")
                            .font(.caption)
                            .foregroundStyle(.black.opacity(0.6))
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            FlagStrip(
                                flags: countryCodes,
                                fontSize: 30,
                                spacing: 10,
                                showsTooltip: false
                            )
                        }
                    }

                    // Placeholder for future map
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.gray.opacity(0.15))
                        .frame(height: 220)
                        .overlay(
                            Text("Interactive map coming soon")
                                .font(.caption)
                                .foregroundColor(.black.opacity(0.5))
                        )
                }
                .padding(.top, 8)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.75))
        )
    }
}

private struct FlagStrip: View {
    let flags: [String] // country codes
    let fontSize: CGFloat
    let spacing: CGFloat
    let showsTooltip: Bool

    init(
        flags: [String],
        fontSize: CGFloat,
        spacing: CGFloat,
        showsTooltip: Bool = false
    ) {
        self.flags = flags
        self.fontSize = fontSize
        self.spacing = spacing
        self.showsTooltip = showsTooltip
    }

    @State private var selectedCode: String? = nil
    @State private var hideWorkItem: DispatchWorkItem? = nil

    private var itemWidth: CGFloat { fontSize + 8 }

    var body: some View {
        LazyHStack(spacing: spacing) {
            ForEach(flags, id: \.self) { code in
                Text(flagEmoji(from: code))
                    .font(.system(size: fontSize))
                    .frame(width: itemWidth, height: fontSize) // fixed size prevents horizontal reflow
                    .fixedSize()
                    .contentShape(Rectangle())
                    .overlay(alignment: .bottom) {
                        if showsTooltip && selectedCode == code {
                            Text(countryName(from: code))
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.gray.opacity(0.92))
                                )
                                .fixedSize()
                                .offset(y: 18) // appears right under the flag without changing layout
                                .transition(.opacity)
                                .zIndex(1)
                        }
                    }
                    .onTapGesture {
                        if showsTooltip {
                            showTooltip(for: code)
                        }
                    }
            }
        }
        .padding(.horizontal, 2)
    }

    private func showTooltip(for code: String) {
        hideWorkItem?.cancel()

        withAnimation(.easeInOut(duration: 0.15)) {
            selectedCode = code
        }

        let work = DispatchWorkItem {
            withAnimation(.easeInOut(duration: 0.15)) {
                if selectedCode == code {
                    selectedCode = nil
                }
            }
        }
        hideWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4, execute: work)
    }

    private func flagEmoji(from countryCode: String) -> String {
        countryCode
            .uppercased()
            .unicodeScalars
            .map { 127397 + $0.value }
            .compactMap(UnicodeScalar.init)
            .map(String.init)
            .joined()
    }

    private func countryName(from code: String) -> String {
        Locale.current.localizedString(forRegionCode: code) ?? code
    }
}
