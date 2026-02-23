//
//  ProfileViewModel+Save.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 2/19/26.
//

import Foundation
import Combine
import Supabase
import PostgREST

extension ProfileViewModel {

    // MARK: - Save (single source of truth)

    func saveProfile(
        firstName: String,
        username: String,
        homeCountries: [String]?,
        languages: [String]?,
        travelMode: String?,
        travelStyle: String?,
        nextDestination: String?,
        avatarUrl: String?
    ) async {
        let userId = self.userId
        errorMessage = nil
        
        let trimmedName = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty, !trimmedUsername.isEmpty else {
            errorMessage = "Name and username are required."
            return
        }
        
        do {
            let payload = ProfileUpdate(
                username: trimmedUsername,
                fullName: trimmedName,
                avatarUrl: avatarUrl,
                languages: languages,
                livedCountries: homeCountries,
                travelStyle: travelStyle.map { [$0] },
                travelMode: travelMode.map { [$0] },
                nextDestination: nextDestination,
                onboardingCompleted: true
            )
            
            try await profileService.updateProfile(
                userId: userId,
                payload: payload
            )
            
            // Reload full profile state
            await reloadProfile()

            print("💾 Saved + fully reloaded profile state")
            
        } catch {
            errorMessage = error.localizedDescription
            print("❌ saveProfile failed:", error)
        }
    }
    
    func uploadAvatar(data: Data, fileName: String) async throws -> String {
        let path = "\(fileName)"
        
        try await profileService.uploadAvatar(
            data: data,
            path: path
        )
        
        return try profileService.publicAvatarURL(path: path)
    }
}
