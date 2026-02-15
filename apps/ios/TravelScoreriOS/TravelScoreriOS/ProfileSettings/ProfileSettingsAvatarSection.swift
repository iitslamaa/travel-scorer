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

    var body: some View {
        SectionCard {
            VStack(spacing: 12) {

                ZStack {
                    if let image = selectedUIImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                    } else if let urlString = profileVM.profile?.avatarUrl,
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

                if isUploadingAvatar {
                    ProgressView()
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}
