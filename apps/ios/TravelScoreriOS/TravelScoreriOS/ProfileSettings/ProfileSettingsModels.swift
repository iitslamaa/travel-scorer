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
        case .budget: return "BUDGET"
        case .comfortable: return "COMFORTABLE"
        case .inBetween: return "IN-between"
        case .both: return "Both on occasion"
        }
    }
}

struct LanguageEntry: Identifiable {
    let id = UUID()
    let name: String
    let proficiency: String

    var display: String {
        "\(name) (\(proficiency))"
    }
}
