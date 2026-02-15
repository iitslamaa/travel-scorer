//
//  FriendsView.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 2/10/26.
//


import SwiftUI
import Supabase
import PostgREST

struct FriendsView: View {
    private let userId: UUID
    @StateObject private var friendsVM = FriendsViewModel()
    @State private var displayName: String = ""

    init(userId: UUID) {
        self.userId = userId
    }

    var body: some View {
        NavigationStack {
            contentView
                .navigationTitle(
                    displayName.isEmpty
                    ? "Friends"
                    : "\(displayName)'s Friends"
                )
                .toolbar {
                    if SupabaseManager.shared.currentUserId == userId {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            NavigationLink {
                                FriendRequestsView()
                            } label: {
                                ZStack(alignment: .topTrailing) {
                                    Image(systemName: "person.crop.circle.badge.plus")
                                        .font(.system(size: 18, weight: .semibold))

                                    if friendsVM.incomingRequestCount > 0 {
                                        Text("\(friendsVM.incomingRequestCount)")
                                            .font(.caption2)
                                            .foregroundColor(.white)
                                            .padding(4)
                                            .background(Color.red)
                                            .clipShape(Circle())
                                            .offset(x: 8, y: -8)
                                    }
                                }
                            }
                        }
                    }
                }
                .searchable(text: $friendsVM.searchText, prompt: "Search by username")
                .onChange(of: friendsVM.searchText) { _ in
                    Task {
                        await friendsVM.searchUsers()
                    }
                }
                .alert("Error", isPresented: .constant(friendsVM.errorMessage != nil)) {
                    Button("OK") {
                        friendsVM.errorMessage = nil
                    }
                } message: {
                    Text(friendsVM.errorMessage ?? "")
                }
                .task {
                    await friendsVM.loadFriends(for: userId)

                    do {
                        let response: PostgrestResponse<Profile> = try await SupabaseManager.shared.client
                            .from("profiles")
                            .select("*")
                            .eq("id", value: userId.uuidString)
                            .single()
                            .execute()

                        displayName = response.value.fullName
                    } catch {
                        displayName = ""
                    }

                    if SupabaseManager.shared.currentUserId == userId {
                        await friendsVM.loadIncomingRequestCount()
                    }
                }
        }
    }

    private var contentView: some View {
        VStack {
            if friendsVM.isLoading {
                ProgressView("Searching…")
                    .padding(.top, 24)
            }

            resultsList
        }
    }

    private var resultsList: some View {
        List {
            if !friendsVM.friends.isEmpty {
                Section {
                    ForEach(friendsVM.friends) { profile in
                        NavigationLink {
                            ProfileView(userId: profile.id)
                        } label: {
                            HStack(spacing: 12) {
                                Group {
                                    if let urlString = profile.avatarUrl,
                                       let url = URL(string: urlString) {
                                        AsyncImage(
                                            url: url,
                                            transaction: Transaction(animation: .easeInOut(duration: 0.2))
                                        ) { phase in
                                            switch phase {
                                            case .success(let image):
                                                image
                                                    .resizable()
                                                    .scaledToFill()
                                                    .transition(.opacity)

                                            case .failure(_):
                                                Image(systemName: "person.crop.circle.fill")
                                                    .resizable()
                                                    .scaledToFill()
                                                    .foregroundStyle(.secondary)

                                            case .empty:
                                                ZStack {
                                                    Circle()
                                                        .fill(Color.gray.opacity(0.15))
                                                    ProgressView()
                                                        .scaleEffect(0.7)
                                                }

                                            @unknown default:
                                                EmptyView()
                                            }
                                        }
                                    } else {
                                        Image(systemName: "person.crop.circle.fill")
                                            .resizable()
                                            .scaledToFill()
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .frame(width: 44, height: 44)
                                .clipShape(Circle())

                                VStack(alignment: .leading) {
                                    Text(profile.fullName)
                                        .fontWeight(.medium)

                                    Text("@\(profile.username)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }

            if !friendsVM.searchResults.isEmpty {
                Section("Results") {
                    ForEach(friendsVM.searchResults) { profile in
                        NavigationLink {
                            ProfileView(userId: profile.id)
                        } label: {
                            HStack(spacing: 12) {
                                Group {
                                    if let urlString = profile.avatarUrl,
                                       let url = URL(string: urlString) {
                                        AsyncImage(
                                            url: url,
                                            transaction: Transaction(animation: .easeInOut(duration: 0.2))
                                        ) { phase in
                                            switch phase {
                                            case .success(let image):
                                                image
                                                    .resizable()
                                                    .scaledToFill()
                                                    .transition(.opacity)

                                            case .failure(_):
                                                Image(systemName: "person.crop.circle.fill")
                                                    .resizable()
                                                    .scaledToFill()
                                                    .foregroundStyle(.secondary)

                                            case .empty:
                                                ZStack {
                                                    Circle()
                                                        .fill(Color.gray.opacity(0.15))
                                                    ProgressView()
                                                        .scaleEffect(0.7)
                                                }

                                            @unknown default:
                                                EmptyView()
                                            }
                                        }
                                    } else {
                                        Image(systemName: "person.crop.circle.fill")
                                            .resizable()
                                            .scaledToFill()
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .frame(width: 44, height: 44)
                                .clipShape(Circle())

                                VStack(alignment: .leading) {
                                    Text(profile.fullName)
                                        .fontWeight(.medium)

                                    Text("@\(profile.username)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            } else if !friendsVM.searchText.isEmpty && !friendsVM.isLoading {
                Text("No users found")
                    .foregroundStyle(.secondary)
            }
            if friendsVM.searchText.isEmpty {
                Section {
                    Text("\(friendsVM.friends.count) \(friendsVM.friends.count == 1 ? "Friend" : "Friends")")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}
