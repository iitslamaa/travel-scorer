//
//  Profile.swift
//  TravelScoreriOS
//

import Foundation

struct Profile: Codable, Identifiable {
    let id: UUID

    var username: String
    var fullName: String
    var avatarUrl: String?

    var languages: [String]
    var livedCountries: [String]
    var travelStyle: [String]
    var travelMode: [String]
    var nextDestination: String?

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
        case nextDestination = "next_destination"
        case onboardingCompleted = "onboarding_completed"
    }

    private struct LanguageObject: Decodable {
        let name: String
        let proficiency: String?
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        username = try container.decode(String.self, forKey: .username)
        fullName = try container.decodeIfPresent(String.self, forKey: .fullName) ?? ""
        avatarUrl = try container.decodeIfPresent(String.self, forKey: .avatarUrl)

        // 🔥 Flexible language decoding
        if let stringArray = try? container.decode([String].self, forKey: .languages) {
            languages = stringArray
        } else if let objectArray = try? container.decode([LanguageObject].self, forKey: .languages) {
            languages = objectArray.map { $0.name }
        } else {
            languages = []
        }

        livedCountries = try container.decodeIfPresent([String].self, forKey: .livedCountries) ?? []
        travelStyle = try container.decodeIfPresent([String].self, forKey: .travelStyle) ?? []
        travelMode = try container.decodeIfPresent([String].self, forKey: .travelMode) ?? []
        nextDestination = try container.decodeIfPresent(String.self, forKey: .nextDestination)
        onboardingCompleted = try container.decodeIfPresent(Bool.self, forKey: .onboardingCompleted)
    }
}
