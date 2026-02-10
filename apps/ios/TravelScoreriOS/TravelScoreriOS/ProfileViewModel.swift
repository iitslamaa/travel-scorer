//
//  ProfileViewModel.swift
//  TravelScoreriOS
//

import Foundation
import Combine

@MainActor
final class ProfileViewModel: ObservableObject {

    // MARK: - Published state
    @Published var profile: Profile?
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Dependencies
    private let profileService: ProfileService
    private var userId: UUID?

    // MARK: - Init
    init(profileService: ProfileService) {
        self.profileService = profileService
    }

    // MARK: - User binding

    func setUserIdIfNeeded(_ newUserId: UUID) {
        if userId == newUserId { return }

        print("🔁 ProfileViewModel binding userId:", newUserId)

        userId = newUserId
        profile = nil
        errorMessage = nil

        Task {
            await load()
        }
    }

    // MARK: - Load
    func load() async {
        guard let userId else {
            print("⚠️ load() skipped — no userId yet")
            return
        }
        if profile != nil {
            print("ℹ️ Profile already loaded — skipping fetch")
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            profile = try await profileService.fetchOrCreateProfile(userId: userId)
            print("📥 Loaded profile:", profile as Any)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Save (single source of truth)
    func saveProfile(
        firstName: String?,
        username: String?,
        homeCountries: [String]?,
        languages: [String]?,
        travelMode: String?,
        travelStyle: String?
    ) async {
        guard let userId else {
            print("⚠️ saveProfile() skipped — no userId")
            return
        }
        errorMessage = nil

        do {
            let payload = ProfileUpdate(
                username: username,
                fullName: firstName,
                avatarUrl: nil,
                languages: languages,
                livedCountries: homeCountries,
                travelStyle: travelStyle.map { [$0] },
                travelMode: travelMode.map { [$0] },
                onboardingCompleted: true
            )

            try await profileService.updateProfile(
                userId: userId,
                payload: payload
            )

            // 🔁 Re-fetch to guarantee consistency
            profile = try await profileService.fetchMyProfile(userId: userId)

            print("💾 Saved + reloaded profile:", profile as Any)

        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
