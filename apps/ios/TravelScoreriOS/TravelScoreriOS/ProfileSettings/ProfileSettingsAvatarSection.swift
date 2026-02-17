//
//  ProfileSettingsAvatarSection.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 2/14/26.
//

import Foundation
import SwiftUI
import PhotosUI

struct ProfileSettingsAvatarSection: View {

    let selectedUIImage: UIImage?
    let profileVM: ProfileViewModel
    @Binding var selectedPhotoItem: PhotosPickerItem?
    let isUploadingAvatar: Bool
    let shouldRemoveAvatar: Bool
    let onRemoveAvatar: () -> Void

    var body: some View {
        SectionCard {
            VStack(spacing: 12) {

                ZStack {
                    if shouldRemoveAvatar {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .foregroundStyle(.secondary)

                    } else if let image = selectedUIImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()

                    } else if let urlString = profileVM.profile?.avatarUrl,
                              !urlString.isEmpty,
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
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 110, height: 110)
                .clipShape(Circle())

                PhotosPicker(
                    selection: $selectedPhotoItem,
                    matching: .images
                ) {
                    Text("Change profile photo")
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                }

                if !shouldRemoveAvatar &&
                   (selectedUIImage != nil ||
                    (profileVM.profile?.avatarUrl?.isEmpty == false)) {
                    Button(role: .destructive) {
                        onRemoveAvatar()
                    } label: {
                        Text("Remove profile photo")
                            .font(.subheadline)
                    }
                }

                if isUploadingAvatar {
                    ProgressView()
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}
