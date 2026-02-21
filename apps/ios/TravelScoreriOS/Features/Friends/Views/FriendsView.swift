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
        let _ = print("📚 FriendsView BODY for:", userId)

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
                    HStack {
                        Text(profile.fullName)
                        Spacer()
                        Text("@\(profile.username)")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationDestination(for: UUID.self) { destinationUserId in
            ProfileView(userId: destinationUserId)
                .id(destinationUserId)
        }
    }
}
