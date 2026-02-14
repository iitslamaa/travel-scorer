//
//  Country.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 11/10/25.
//

import Foundation

struct Country: Identifiable, Hashable {
    let iso2: String
    /// Stable identifier for persistence (do NOT use random UUIDs).
    var id: String { iso2.uppercased() }
    let name: String
    let score: Int
    let region: String?
    let subregion: String?
    let advisoryLevel: String?
    
    let travelSafeScore: Int?

    // Extra details from API
    let advisorySummary: String?
    let advisoryUpdatedAt: String?
    let advisoryUrl: URL?

    // Seasonality
    let seasonalityScore: Int?
    let seasonalityLabel: String?
    let seasonalityBestMonths: [Int]?
    let seasonalityNotes: String?

    // Visa
    let visaEaseScore: Int?
    let visaType: String?
    let visaAllowedDays: Int?
    let visaFeeUsd: Double?
    let visaNotes: String?
    let visaSourceUrl: URL?

    // Daily spend
    let dailySpendTotalUsd: Double?
    let dailySpendHotelUsd: Double?
    let dailySpendFoodUsd: Double?
    let dailySpendActivitiesUsd: Double?
    
    // Nice combined label for UI, similar to web
    var regionLabel: String? {
        switch (subregion, region) {
        case let (sub?, reg?) where sub != reg:
            // e.g. "Western Europe, Europe" or "South America, Latin America & Caribbean"
            return "\(sub), \(reg)"
        case (nil, let reg?):
            return reg
        case (let sub?, nil):
            return sub
        default:
            return nil
        }
    }
    
    // Convert advisory level string (e.g. "Level 1") into a normalized numeric score
    var advisoryScore: Int? {
        guard let levelString = advisoryLevel else { return nil }

        if levelString.contains("1") {
            return 90
        } else if levelString.contains("2") {
            return 70
        } else if levelString.contains("3") {
            return 40
        } else if levelString.contains("4") {
            return 10
        }

        return nil
    }

    // Custom initializer to maintain compatibility
    init(
        iso2: String,
        name: String,
        score: Int,
        region: String? = nil,
        subregion: String? = nil,
        advisoryLevel: String?,
        advisorySummary: String? = nil,
        advisoryUpdatedAt: String? = nil,
        advisoryUrl: URL? = nil,
        seasonalityScore: Int? = nil,
        seasonalityLabel: String? = nil,
        seasonalityBestMonths: [Int]? = nil,
        seasonalityNotes: String? = nil,
        visaEaseScore: Int? = nil,
        visaType: String? = nil,
        visaAllowedDays: Int? = nil,
        visaFeeUsd: Double? = nil,
        visaNotes: String? = nil,
        visaSourceUrl: URL? = nil,
        dailySpendTotalUsd: Double? = nil,
        dailySpendHotelUsd: Double? = nil,
        dailySpendFoodUsd: Double? = nil,
        dailySpendActivitiesUsd: Double? = nil,
        travelSafeScore: Int? = nil
    ) {
        self.iso2 = iso2
        self.name = name
        self.score = score
        self.region = region
        self.subregion = subregion
        self.advisoryLevel = advisoryLevel
        self.advisorySummary = advisorySummary
        self.advisoryUpdatedAt = advisoryUpdatedAt
        self.advisoryUrl = advisoryUrl
        self.seasonalityScore = seasonalityScore
        self.seasonalityLabel = seasonalityLabel
        self.seasonalityBestMonths = seasonalityBestMonths
        self.seasonalityNotes = seasonalityNotes
        self.visaEaseScore = visaEaseScore
        self.visaType = visaType
        self.visaAllowedDays = visaAllowedDays
        self.visaFeeUsd = visaFeeUsd
        self.visaNotes = visaNotes
        self.visaSourceUrl = visaSourceUrl
        self.dailySpendTotalUsd = dailySpendTotalUsd
        self.dailySpendHotelUsd = dailySpendHotelUsd
        self.dailySpendFoodUsd = dailySpendFoodUsd
        self.dailySpendActivitiesUsd = dailySpendActivitiesUsd
        self.travelSafeScore = travelSafeScore
    }

    var flagEmoji: String {
        iso2.flagEmoji
    }
}

enum CountrySort: String, CaseIterable {
    case name = "Name"
    case score = "Score"
}

// MARK: - ISO2 -> Flag emoji

extension String {
    /// Converts a 2-letter ISO country code (e.g. "US", "EG") into a flag emoji (🇺🇸, 🇪🇬).
    var flagEmoji: String {
        let uppercased = self.uppercased()
        guard uppercased.count == 2 else { return "🏳️" }

        let base: UInt32 = 127397 // Unicode for regional indicator 'A' minus "A"
        var scalars = String.UnicodeScalarView()

        for scalar in uppercased.unicodeScalars {
            guard let flagScalar = UnicodeScalar(base + scalar.value) else { continue }
            scalars.append(flagScalar)
        }

        return String(scalars)
    }
}
