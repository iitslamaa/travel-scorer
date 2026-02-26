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

enum LanguageComfort: String, CaseIterable, Identifiable {
    case nativeLevel
    case fluent
    case comfortable
    case conversational

    var id: String { rawValue }

    var label: String {
        switch self {
        case .nativeLevel: return "Native-level"
        case .fluent: return "Fluent"
        case .comfortable: return "Comfortable"
        case .conversational: return "Conversational"
        }
    }
}

struct LanguageEntry: Identifiable, Equatable {
    let id = UUID()
    let code: String
    var comfort: LanguageComfort
    var isLearning: Bool
    var isPreferred: Bool

    var display: String {
        var parts = [comfort.label]
        if isLearning { parts.append("Learning") }
        return parts.joined(separator: " • ")
    }
}
