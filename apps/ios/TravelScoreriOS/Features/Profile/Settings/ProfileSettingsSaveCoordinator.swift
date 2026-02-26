//
//  ProfileSettingsSaveCoordinator.swift
//  TravelScoreriOS
//

import UIKit

struct ProfileSettingsSaveCoordinator {

    static func handleSave(
        profileVM: ProfileViewModel,
        firstName: String,
        username: String,
        homeCountries: Set<String>,
        languages: [LanguageEntry],
        travelMode: TravelMode?,
        travelStyle: TravelStyle?,
        nextDestination: String?,
        selectedUIImage: UIImage?,
        shouldRemoveAvatar: Bool,
        setSaving: @escaping (Bool) -> Void,
        setAvatarUploading: @escaping (Bool) -> Void,
        setAvatarCleared: @escaping () -> Void,
        showSuccess: @escaping () -> Void,
        hideSuccess: @escaping () -> Void
    ) async {

        setSaving(true)

        let avatarURL = await resolveAvatarChange(
            profileVM: profileVM,
            selectedUIImage: selectedUIImage,
            shouldRemoveAvatar: shouldRemoveAvatar,
            setAvatarUploading: setAvatarUploading
        )

        let trimmedName = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)

        await profileVM.saveProfile(
            firstName: trimmedName,
            username: trimmedUsername,
            homeCountries: Array(homeCountries).sorted(),
            languages: languages.map { $0.name },
            travelMode: travelMode?.rawValue,
            travelStyle: travelStyle?.rawValue,
            nextDestination: nextDestination,
            avatarUrl: avatarURL
        )

        setSaving(false)

        // Clear temporary avatar state
        setAvatarCleared()

        showSuccess()

        try? await Task.sleep(nanoseconds: 1_800_000_000)

        hideSuccess()
    }

    // MARK: - Avatar Handling

    private static func resolveAvatarChange(
        profileVM: ProfileViewModel,
        selectedUIImage: UIImage?,
        shouldRemoveAvatar: Bool,
        setAvatarUploading: @escaping (Bool) -> Void
    ) async -> String? {

        if shouldRemoveAvatar {
            return ""
        }

        return await uploadAvatarIfNeeded(
            profileVM: profileVM,
            image: selectedUIImage,
            setAvatarUploading: setAvatarUploading
        )
    }

    private static func uploadAvatarIfNeeded(
        profileVM: ProfileViewModel,
        image: UIImage?,
        setAvatarUploading: @escaping (Bool) -> Void
    ) async -> String? {

        guard
            let image,
            let userId = profileVM.profile?.id,
            let data = image.jpegData(compressionQuality: 0.85)
        else {
            return nil
        }

        setAvatarUploading(true)
        defer { setAvatarUploading(false) }

        let fileName = "\(userId)_\(UUID().uuidString).jpg"

        do {
            let publicURL = try await profileVM.uploadAvatar(
                data: data,
                fileName: fileName
            )
            return publicURL
        } catch {
            print("🔴 Avatar upload failed:", error)
            return nil
        }
    }
}
