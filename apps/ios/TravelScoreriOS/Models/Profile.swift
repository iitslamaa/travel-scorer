//
//  Profile.swift
//  TravelScoreriOS
//

import Foundation

struct AnyCodable: Codable {
    let value: Any

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let int = try? container.decode(Int.self) { value = int }
        else if let double = try? container.decode(Double.self) { value = double }
        else if let bool = try? container.decode(Bool.self) { value = bool }
        else if let string = try? container.decode(String.self) { value = string }
        else if let array = try? container.decode([AnyCodable].self) { value = array.map { $0.value } }
        else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues { $0.value }
        } else {
            value = NSNull()
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let int as Int: try container.encode(int)
        case let double as Double: try container.encode(double)
        case let bool as Bool: try container.encode(bool)
        case let string as String: try container.encode(string)
        case let array as [Any]: try container.encode(array.map { AnyCodable(value: $0) })
        case let dict as [String: Any]: try container.encode(dict.mapValues { AnyCodable(value: $0) })
        default: try container.encodeNil()
        }
    }

    init(value: Any) {
        self.value = value
    }
}

struct Profile: Codable, Identifiable {
    let id: UUID

    var username: String
    var fullName: String
    var avatarUrl: String?

    var languages: [[String: Any]]
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

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        username = try container.decode(String.self, forKey: .username)
        fullName = try container.decodeIfPresent(String.self, forKey: .fullName) ?? ""
        avatarUrl = try container.decodeIfPresent(String.self, forKey: .avatarUrl)

        // 🔥 Flexible language decoding (supports legacy [String] and new [[String: Any]])
        if let objectArray = try? container.decode([[String: AnyCodable]].self, forKey: .languages) {
            languages = objectArray.map { dict in
                dict.mapValues { $0.value }
            }
        } else if let stringArray = try? container.decode([String].self, forKey: .languages) {
            languages = stringArray.map {
                [
                    "code": $0,
                    "comfort": "nativeLevel",
                    "learning": false,
                    "preferred": false
                ]
            }
        } else {
            languages = []
        }

        livedCountries = try container.decodeIfPresent([String].self, forKey: .livedCountries) ?? []
        travelStyle = try container.decodeIfPresent([String].self, forKey: .travelStyle) ?? []
        travelMode = try container.decodeIfPresent([String].self, forKey: .travelMode) ?? []
        nextDestination = try container.decodeIfPresent(String.self, forKey: .nextDestination)
        onboardingCompleted = try container.decodeIfPresent(Bool.self, forKey: .onboardingCompleted)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(username, forKey: .username)
        try container.encode(fullName, forKey: .fullName)
        try container.encodeIfPresent(avatarUrl, forKey: .avatarUrl)

        // Convert [[String: Any]] → [[String: AnyCodable]] for encoding
        let encodedLanguages = languages.map { dict in
            dict.mapValues { AnyCodable(value: $0) }
        }
        try container.encode(encodedLanguages, forKey: .languages)

        try container.encode(livedCountries, forKey: .livedCountries)
        try container.encode(travelStyle, forKey: .travelStyle)
        try container.encode(travelMode, forKey: .travelMode)
        try container.encodeIfPresent(nextDestination, forKey: .nextDestination)
        try container.encodeIfPresent(onboardingCompleted, forKey: .onboardingCompleted)
    }
}
