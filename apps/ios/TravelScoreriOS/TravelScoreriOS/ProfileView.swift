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

    var body: some View {
        ZStack {
            Image("profile_background")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

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
            Task { try? await profileVM.refreshRelationshipState() }
        }
    }

    private var profileHeader: some View {
        HStack(alignment: .center, spacing: 16) {

            Group {
                if let urlString = profileVM.profile?.avatarUrl,
                   let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        if let image = phase.image {
                            image.resizable().scaledToFill()
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

                // Friend action button (small grey rectangle like original design)
                if profileVM.relationshipState != .selfProfile {
                    Button {
                        if profileVM.relationshipState == .friends {
                            showUnfriendConfirmation = true
                        } else {
                            Task {
                                await profileVM.toggleFriend()
                            }
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
                    .buttonStyle(.bordered)
                    .tint(.gray)
                    .disabled(profileVM.relationshipState == .requestSent)
                    .alert("Unfriend?", isPresented: $showUnfriendConfirmation) {
                        Button("Cancel", role: .cancel) {}
                        Button("Confirm", role: .destructive) {
                            Task {
                                await profileVM.toggleFriend()
                            }
                        }
                    } message: {
                        Text("Are you sure you want to remove this friend?")
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
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.75))
        )
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
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.75))
        )
    }

    private func flags(for ids: Set<String>) -> [String] {
        ids.map { $0.uppercased() }.sorted()
    }
}

struct CollapsibleCountrySection: View {
    let title: String
    let countryCodes: [String]
    let highlightColor: Color
    let mutualCountries: Set<String>?

    @State private var isExpanded = false
    @State private var selectedCountryISO: String? = nil

    init(
        title: String,
        countryCodes: [String],
        highlightColor: Color,
        mutualCountries: Set<String>? = nil
    ) {
        self.title = title
        self.countryCodes = countryCodes
        self.highlightColor = highlightColor
        self.mutualCountries = mutualCountries
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            Button {
                withAnimation(.easeInOut(duration: 0.18)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
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

                    ScrollView(.horizontal, showsIndicators: false) {
                        FlagStrip(
                            flags: countryCodes,
                            fontSize: 30,
                            spacing: 10,
                            showsTooltip: false,
                            selectedISO: selectedCountryISO,
                            onFlagTap: { selectedCountryISO = $0 },
                            mutualCountries: mutualCountries
                        )
                    }

                    ZStack(alignment: .bottom) {

                        WorldMapView(
                            highlightedCountryCodes: countryCodes,
                            selectedCountryISO: $selectedCountryISO
                        )
                        .frame(height: 240)
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                        if let iso = selectedCountryISO {
                            HStack(spacing: 8) {
                                Text(flagEmoji(from: iso))
                                Text(Locale.current.localizedString(forRegionCode: iso) ?? iso)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                            .padding(.bottom, 12)
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.75))
        )
    }

    private func flagEmoji(from code: String) -> String {
        code.uppercased().unicodeScalars
            .map { 127397 + $0.value }
            .compactMap(UnicodeScalar.init)
            .map(String.init)
            .joined()
    }
}

struct FlagStrip: View {
    let flags: [String]
    let fontSize: CGFloat
    let spacing: CGFloat
    let showsTooltip: Bool
    let selectedISO: String?
    let onFlagTap: ((String) -> Void)?
    let mutualCountries: Set<String>?

    init(
        flags: [String],
        fontSize: CGFloat,
        spacing: CGFloat,
        showsTooltip: Bool = false,
        selectedISO: String? = nil,
        onFlagTap: ((String) -> Void)? = nil,
        mutualCountries: Set<String>? = nil
    ) {
        self.flags = flags
        self.fontSize = fontSize
        self.spacing = spacing
        self.showsTooltip = showsTooltip
        self.selectedISO = selectedISO
        self.onFlagTap = onFlagTap
        self.mutualCountries = mutualCountries
    }

    var body: some View {
        LazyHStack(spacing: spacing) {
            ForEach(flags, id: \.self) { code in
                let flag = flagEmoji(from: code)
                let isMutual = mutualCountries?.contains(code) ?? false
                let isSelected = selectedISO == code

                Text(flag)
                    .font(.system(size: fontSize))
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(
                                isMutual
                                ? Color.gold.opacity(0.35)
                                : (isSelected ? Color.blue.opacity(0.25) : Color.clear)
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(
                                isSelected ? Color.blue :
                                (isMutual ? Color.gold : Color.clear),
                                lineWidth: 2
                            )
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onFlagTap?(code)
                    }
            }
        }
    }

    private func flagEmoji(from code: String) -> String {
        code.uppercased().unicodeScalars
            .map { 127397 + $0.value }
            .compactMap(UnicodeScalar.init)
            .map(String.init)
            .joined()
    }
}
