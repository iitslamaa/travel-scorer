//
//  ProfileViewModel.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 2/9/26.
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
    private let userId: UUID

    // MARK: - Init

    init(profileService: ProfileService, userId: UUID) {
        self.profileService = profileService
        self.userId = userId
    }

    // MARK: - Load

    func load() async {
        isLoading = true
        errorMessage = nil

        do {
            profile = try await profileService.fetchOrCreateProfile(userId: userId)
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

            // Ensure we have a cached profile
            if profile == nil {
                profile = try await profileService.fetchMyProfile(userId: userId)
            }

            // Update local state for immediate UI refresh
            profile?.username = username
            profile?.fullName = firstName
            profile?.languages = languages ?? []
            profile?.livedCountries = homeCountries ?? []
            profile?.travelStyle = travelStyle.map { [$0] } ?? []
            profile?.travelMode = travelMode.map { [$0] } ?? []

        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
