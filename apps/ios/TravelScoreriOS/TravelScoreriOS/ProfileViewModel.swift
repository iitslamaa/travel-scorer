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
    @Published var profile: Profile?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let profileService: ProfileService
    private let userId: UUID

    init(profileService: ProfileService, userId: UUID) {
        self.profileService = profileService
        self.userId = userId
    }

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

    func updateUsername(_ username: String) async {
        guard !username.isEmpty else { return }

        do {
            try await profileService.updateProfile(
                userId: userId,
                payload: ProfileUpdate(
                    username: username,
                    fullName: nil,
                    avatarUrl: nil,
                    languages: nil,
                    livedCountries: nil,
                    travelStyle: nil,
                    travelMode: nil,
                    onboardingCompleted: nil
                )
            )

            profile?.username = username
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
