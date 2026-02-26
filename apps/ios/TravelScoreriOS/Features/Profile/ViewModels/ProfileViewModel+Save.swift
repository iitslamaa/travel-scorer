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
        languages: [[String: AnyCodable]]?,
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

            // 🔥 META GOLD STANDARD: deterministic local state merge (no immediate refetch)
            if var current = profile {
                current.username = trimmedUsername
                current.fullName = trimmedName
                current.livedCountries = homeCountries ?? current.livedCountries
                if let languages {
                    current.languages = languages
                }
                current.travelStyle = travelStyle.map { [$0] } ?? current.travelStyle
                current.travelMode = travelMode.map { [$0] } ?? current.travelMode
                current.nextDestination = nextDestination

                // Handle avatarUrl explicitly ("" means remove)
                if let avatarUrl {
                    current.avatarUrl = avatarUrl.isEmpty ? nil : avatarUrl
                }

                profile = current
            }

            print("💾 Saved + locally merged profile state (no reload)")
            
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
