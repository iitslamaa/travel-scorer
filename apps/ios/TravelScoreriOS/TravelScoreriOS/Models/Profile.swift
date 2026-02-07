//
//  Profile.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 2/6/26.
//

import Foundation

struct Profile: Codable, Identifiable {
    let id: UUID

    var username: String?
    var fullName: String?
    var avatarUrl: String?

    var languages: [String]
    var livedCountries: [String]
    var travelStyle: [String]
    var travelMode: [String]

    var onboardingCompleted: Bool?

    enum CodingKeys: String, CodingKey {
        case id
        case username
        case fullName = "full_name"
        case avatarUrl = "avatar_url"
        case languages
        case livedCountries = "lived_countries"
        case travelStyle = "travel_style"
        case travelMode = "travel_mode"
        case onboardingCompleted = "onboarding_completed"
    }
}
