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
                            VStack(alignment: .leading) {
                                Text(profile.fullName)
                                    .fontWeight(.medium)

                                Text("@\(profile.username)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
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
                            VStack(alignment: .leading) {
                                Text(profile.fullName)
                                    .fontWeight(.medium)

                                Text("@\(profile.username)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            } else if !friendsVM.searchText.isEmpty && !friendsVM.isLoading {
                Text("No users found")
                    .foregroundStyle(.secondary)
            }
        }
        .listStyle(.insetGrouped)
    }
}
