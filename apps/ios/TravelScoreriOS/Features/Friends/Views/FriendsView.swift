import SwiftUI

struct FriendsView: View {
    private let userId: UUID
    @StateObject private var friendsVM = FriendsViewModel()
    @State private var displayName: String = ""
    @State private var showFriendRequests: Bool = false

    init(userId: UUID) {
        self.userId = userId
        print("👥 FriendsView INIT")
        print("   userId:", userId)
    }

    var body: some View {
        contentView
            .navigationTitle(
                displayName.isEmpty
                ? "Friends"
                : "\(displayName)'s Friends"
            )
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if SupabaseManager.shared.currentUserId == userId {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showFriendRequests = true
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(Color(.systemGray5))
                                    .frame(width: 36, height: 36)

                                Image(systemName: "person.crop.circle.badge.plus")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(.primary)

                                if friendsVM.incomingRequestCount > 0 {
                                    Text("\(min(friendsVM.incomingRequestCount, 9))")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(.white)
                                        .frame(width: 16, height: 16)
                                        .background(
                                            Circle().fill(.red)
                                        )
                                        .offset(x: 10, y: -10)
                                }
                            }
                            .contentShape(Circle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationDestination(isPresented: $showFriendRequests) {
                FriendRequestsView()
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
            .task(id: userId) {
                await friendsVM.loadFriends(for: userId)

                if friendsVM.displayName.isEmpty {
                    await friendsVM.loadDisplayName(for: userId)
                    displayName = friendsVM.displayName
                }

                if SupabaseManager.shared.currentUserId == userId {
                    await friendsVM.loadIncomingRequestCount()
                }
            }
    }

    private var contentView: some View {
        List {
            ForEach(friendsVM.friends) { profile in
                NavigationLink(value: profile.id) {
                    HStack(spacing: 14) {

                        // Profile Avatar
                        if let urlString = profile.avatarUrl,
                           let url = URL(string: urlString) {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                Image(systemName: "person.crop.circle.fill")
                                    .resizable()
                                    .scaledToFill()
                                    .foregroundStyle(.secondary)
                            }
                            .frame(width: 44, height: 44)
                            .clipShape(Circle())
                        } else {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .scaledToFill()
                                .foregroundStyle(.secondary)
                                .frame(width: 44, height: 44)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(profile.fullName)
                                .font(.headline)

                            Text("@\(profile.username)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                        // ❌ Remove manual chevron — List provides the correct system arrow automatically
                    }
                    .padding(.vertical, 6)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationDestination(for: UUID.self) { destinationUserId in
            ProfileView(userId: destinationUserId)
                .id(destinationUserId)
        }
    }
}
