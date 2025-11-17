//
//  Country.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 11/10/25.
//

import Foundation

struct Country: Identifiable, Hashable {
    let id = UUID()
    let iso2: String
    let name: String
    let score: Int
    let advisoryLevel: String?

    // Extra details from API
    let advisorySummary: String?
    let advisoryUpdatedAt: String?
    let advisoryUrl: URL?

    // Seasonality
    let seasonalityScore: Int?
    let seasonalityLabel: String?
    let seasonalityBestMonths: [Int]?

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

    // Custom initializer to maintain compatibility
    init(
        iso2: String,
        name: String,
        score: Int,
        advisoryLevel: String?,
        advisorySummary: String? = nil,
        advisoryUpdatedAt: String? = nil,
        advisoryUrl: URL? = nil,
        seasonalityScore: Int? = nil,
        seasonalityLabel: String? = nil,
        seasonalityBestMonths: [Int]? = nil,
        visaEaseScore: Int? = nil,
        visaType: String? = nil,
        visaAllowedDays: Int? = nil,
        visaFeeUsd: Double? = nil,
        visaNotes: String? = nil,
        visaSourceUrl: URL? = nil,
        dailySpendTotalUsd: Double? = nil,
        dailySpendHotelUsd: Double? = nil,
        dailySpendFoodUsd: Double? = nil,
        dailySpendActivitiesUsd: Double? = nil
    ) {
        self.iso2 = iso2
        self.name = name
        self.score = score
        self.advisoryLevel = advisoryLevel
        self.advisorySummary = advisorySummary
        self.advisoryUpdatedAt = advisoryUpdatedAt
        self.advisoryUrl = advisoryUrl
        self.seasonalityScore = seasonalityScore
        self.seasonalityLabel = seasonalityLabel
        self.seasonalityBestMonths = seasonalityBestMonths
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
