import SwiftUI
import NukeUI
import Nuke

struct ProfileHeaderView: View {
    private let instanceId = UUID()
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
        let _ = print("🧾 ProfileHeaderView BODY — instance:", instanceId,
                      " profile.id:", profile?.id as Any,
                      " relationshipState:", relationshipState as Any,
                      " effectiveState:", effectiveState,
                      " friendCount:", friendCount)
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
                            print("🔘 Friend button tapped — instance:", instanceId,
                                  " profile.id:", profile?.id as Any,
                                  " currentState:", effectiveState,
                                  " friendCount:", friendCount)
                            onToggleFriend()
                        }) {
                            HStack(spacing: 6) {

                                switch effectiveState {
                                case .friends:
                                    Image(systemName: "checkmark")
                                case .requestSent:
                                    Image(systemName: "clock")
                                case .requestReceived:
                                    Image(systemName: "checkmark.circle.fill")
                                case .none:
                                    Image(systemName: "person.badge.plus")
                                case .selfProfile:
                                    EmptyView()
                                }

                                Text(buttonLabel(for: effectiveState))
                                    .font(.caption)
                                    .fontWeight(.semibold)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 9)
                            .background(
                                Capsule()
                                    .fill(backgroundColor(for: effectiveState))
                            )
                            .foregroundStyle(foregroundColor(for: effectiveState))
                        }
                    }
                }

                Spacer()
            }
        }
        .onChange(of: profile?.id) { oldValue, newValue in
            print("🔁 ProfileHeaderView profile.id changed — instance:", instanceId,
                  " old:", oldValue as Any,
                  " new:", newValue as Any)
        }
        .onChange(of: relationshipState) { oldValue, newValue in
            print("🔁 ProfileHeaderView relationshipState changed — instance:", instanceId,
                  " old:", oldValue as Any,
                  " new:", newValue as Any)
        }
        .onChange(of: friendCount) { oldValue, newValue in
            print("🔁 ProfileHeaderView friendCount changed — instance:", instanceId,
                  " old:", oldValue,
                  " new:", newValue)
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

                LazyImage(url: url) { state in
                    if let image = state.image {
                        image
                            .resizable()
                            .scaledToFill()
                    } else if state.error != nil {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .scaledToFill()
                            .foregroundStyle(.gray)
                    } else {
                        ZStack {
                            Circle()
                                .fill(Color.gray.opacity(0.15))
                            ProgressView()
                        }
                    }
                }
                .processors([
                    ImageProcessors.Resize(size: CGSize(width: 300, height: 300))
                ])
                .priority(.high)

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
        case .requestReceived:
            return "Accept"
        case .friends:
            return friendCount == 1 ? "1 Friend" : "\(friendCount) Friends"
        case .selfProfile:
            return ""
        }
    }

    private func backgroundColor(for state: RelationshipState) -> Color {
        switch state {
        case .none:
            return Color.blue.opacity(0.12)
        case .requestSent:
            return Color.gray.opacity(0.15)
        case .requestReceived:
            return Color.green.opacity(0.18)
        case .friends:
            return Color.blue.opacity(0.18)
        case .selfProfile:
            return .clear
        }
    }

    private func foregroundColor(for state: RelationshipState) -> Color {
        switch state {
        case .requestSent:
            return .gray
        case .requestReceived:
            return .green
        default:
            return .blue
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
