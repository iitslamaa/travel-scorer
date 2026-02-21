import SwiftUI

struct FriendsView: View {
    private let userId: UUID
    @StateObject private var friendsVM = FriendsViewModel()
    @State private var displayName: String = ""

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
                        NavigationLink {
                            FriendRequestsView()
                        } label: {
                            ZStack(alignment: .topTrailing) {
                                Image(systemName: "person.crop.circle.badge.plus")
                                    .font(.system(size: 20, weight: .semibold))

                                if friendsVM.incomingRequestCount > 0 {
                                    Text("\(friendsVM.incomingRequestCount)")
                                        .font(.caption2)
                                        .foregroundColor(.white)
                                        .padding(5)
                                        .background(Color.red)
                                        .clipShape(Circle())
                                        .offset(x: 10, y: -10)
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
