import SwiftUI

struct ProfileHeaderView: View {
    let profile: Profile?
    let username: String
    let homeCountryCodes: [String]
    let relationshipState: RelationshipState?
    let friendCount: Int
    let onToggleFriend: () -> Void

    private var effectiveState: RelationshipState {
        relationshipState ?? .none
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            HStack(alignment: .center, spacing: 20) {

                avatarView
                    .frame(width: 110, height: 110)

                VStack(alignment: .leading, spacing: 6) {

                    Text(profile?.fullName ?? "")
                        .font(.title2)
                        .fontWeight(.bold)

                    if !username.isEmpty {
                        Text("@\(username)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    if !homeCountryCodes.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(homeCountryCodes, id: \.self) { code in
                                    Text(flagEmoji(for: code))
                                        .font(.title3)
                                }
                            }
                        }
                    }

                    if effectiveState != .selfProfile {

                        Button(action: {
                            onToggleFriend()
                        }) {
                            HStack(spacing: 6) {

                                if effectiveState == .friends {
                                    Image(systemName: "checkmark")
                                }

                                Text(buttonLabel(for: effectiveState))
                                    .font(.caption)
                                    .fontWeight(.semibold)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 9)
                            .background(
                                Capsule()
                                    .fill(
                                        effectiveState == .friends
                                        ? Color.blue.opacity(0.18)
                                        : Color.blue.opacity(0.12)
                                    )
                            )
                        }
                    }
                }

                Spacer()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
    }

    // MARK: - Avatar

    private var avatarView: some View {
        Group {
            if let urlString = profile?.avatarUrl,
               let url = URL(string: urlString) {

                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()

                    case .failure(_):
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .scaledToFill()
                            .foregroundStyle(.gray)

                    case .empty:
                        ZStack {
                            Circle()
                                .fill(Color.gray.opacity(0.15))
                            ProgressView()
                        }

                    @unknown default:
                        EmptyView()
                    }
                }

            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .scaledToFill()
                    .foregroundStyle(.gray)
            }
        }
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(Color(.systemBackground), lineWidth: 3)
        )
        .shadow(radius: 6)
    }

    private func buttonLabel(for state: RelationshipState) -> String {
        switch state {
        case .none:
            return "Add Friend"
        case .requestSent:
            return "Request Sent"
        case .friends:
            return friendCount == 1 ? "1 Friend" : "\(friendCount) Friends"
        case .selfProfile:
            return ""
        }
    }

    private func flagEmoji(for countryCode: String) -> String {
        countryCode
            .uppercased()
            .unicodeScalars
            .compactMap { UnicodeScalar(127397 + $0.value) }
            .map { String($0) }
            .joined()
    }
}
