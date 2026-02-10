//
//  FriendsView.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 2/10/26.
//

import SwiftUI

struct FriendsView: View {
    @EnvironmentObject private var profileVM: ProfileViewModel
    @StateObject private var friendsVM = FriendsViewModel()

    var body: some View {
        NavigationStack {
            VStack {
                if friendsVM.isLoading {
                    ProgressView("Searching…")
                        .padding(.top, 24)
                }

                List {
                    if !friendsVM.searchResults.isEmpty {
                        Section("Results") {
                            ForEach(friendsVM.searchResults) { profile in
                                NavigationLink {
                                    // Navigate to someone else's profile
                                    ProfileView()
                                        .onAppear {
                                            profileVM.setUserIdIfNeeded(profile.id)
                                        }
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(profile.fullName)
                                                .fontWeight(.medium)

                                            Text("@\(profile.username)")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }

                                        Spacer()
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
            .navigationTitle("Friends")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        FriendRequestsView()
                    } label: {
                        Image(systemName: "person.crop.circle.badge.plus")
                    }
                    .accessibilityLabel("Friend Requests")
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
        }
    }
}
