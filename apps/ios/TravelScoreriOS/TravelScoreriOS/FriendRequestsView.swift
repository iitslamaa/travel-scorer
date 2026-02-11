//
//  FriendRequestsView.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 2/10/26.
//

import SwiftUI

struct FriendRequestsView: View {
    @StateObject private var vm = FriendRequestsViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if vm.isLoading {
                    ProgressView("Loading requests…")
                } else if vm.incomingRequests.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "person.crop.circle.badge.plus")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)

                        Text("No friend requests")
                            .font(.headline)

                        Text("When someone sends you a friend request, it’ll show up here.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    List {
                        ForEach(vm.incomingRequests) { profile in
                            HStack(spacing: 12) {

                                // Avatar
                                Group {
                                    if let urlString = profile.avatarUrl,
                                       let url = URL(string: urlString) {
                                        AsyncImage(url: url) { phase in
                                            if let image = phase.image {
                                                image
                                                    .resizable()
                                                    .scaledToFill()
                                            } else {
                                                Image(systemName: "person.crop.circle.fill")
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                    } else {
                                        Image(systemName: "person.crop.circle.fill")
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .frame(width: 44, height: 44)
                                .clipShape(Circle())

                                // Name + username
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(profile.fullName)
                                        .fontWeight(.medium)

                                    Text("@\(profile.username)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                // Accept / Decline
                                HStack(spacing: 8) {
                                    Button("Accept") {
                                        Task {
                                            do {
                                                try await vm.acceptRequest(from: profile.id)
                                                print("✅ friendship insert attempted")
                                            } catch {
                                                print("❌ accept failed:", error)
                                            }
                                            await vm.loadIncomingRequests()
                                        }
                                    }
                                    .buttonStyle(.borderedProminent)

                                    Button("Decline") {
                                        Task {
                                            try? await vm.rejectRequest(from: profile.id)
                                            await vm.loadIncomingRequests()
                                        }
                                    }
                                    .buttonStyle(.bordered)
                                }
                            }
                            .padding(.vertical, 6)
                        }
                    }
                }
            }
            .navigationTitle("Friend Requests")
            .task {
                await vm.loadIncomingRequests()
            }
            .alert("Error", isPresented: .constant(vm.errorMessage != nil)) {
                Button("OK") {
                    vm.errorMessage = nil
                }
            } message: {
                Text(vm.errorMessage ?? "")
            }
        }
    }
}
