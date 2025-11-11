//
//  Country.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 11/10/25.
//

import Foundation

struct Country: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let score: Int
    let advisoryLevel: String?
    
    var flagEmoji: String {
        switch name {
        case "Japan": return "🇯🇵"
        case "United Arab Emirates", "UAE": return "🇦🇪"
        case "Qatar": return "🇶🇦"
        case "Bahrain": return "🇧🇭"
        case "Kuwait": return "🇰🇼"
        case "Oman": return "🇴🇲"
        case "Yemen": return "🇾🇪"
        case "Jordan": return "🇯🇴"
        case "Lebanon": return "🇱🇧"
        case "Syria": return "🇸🇾"
        case "Iraq": return "🇮🇶"
        case "Egypt": return "🇪🇬"
        case "Palestine": return "🇵🇸"
        case "Morocco": return "🇲🇦"
        case "Algeria": return "🇩🇿"
        case "Tunisia": return "🇹🇳"
        case "Libya": return "🇱🇾"
        case "Brazil": return "🇧🇷"
        case "Iceland": return "🇮🇸"
        default: return "🌍"
        }
    }
}

enum CountrySort: String, CaseIterable {
    case name = "Name"
    case score = "Score"
}
