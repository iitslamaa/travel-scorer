//
//  ProfileSettingsModels.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 2/14/26.
//

import Foundation

enum TravelMode: String, CaseIterable, Identifiable {
    case solo, group, both
    var id: String { rawValue }
    var label: String {
        switch self {
        case .solo: return "Solo"
        case .group: return "Group"
        case .both: return "Solo + Group"
        }
    }
}

enum TravelStyle: String, CaseIterable, Identifiable {
    case budget, comfortable, inBetween, both
    var id: String { rawValue }
    var label: String {
        switch self {
        case .budget: return "Budget"
        case .comfortable: return "Comfortable"
        case .inBetween: return "In Between"
        case .both: return "Both on Occasion"
        }
    }
}

enum LanguageProficiency: String, CaseIterable, Codable {
    case learning = "Learning"
    case conversational = "Conversational"
    case fluent = "Fluent"
}

struct LanguageEntry: Identifiable, Equatable, Codable {
    let id: UUID
    let name: String
    let proficiency: LanguageProficiency

    init(id: UUID = UUID(), name: String, proficiency: LanguageProficiency) {
        self.id = id
        self.name = name
        self.proficiency = proficiency
    }

    var display: String {
        "\(name) (\(proficiency.rawValue))"
    }
}
