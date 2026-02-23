//
//  WhenToGoViewModel.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 1/22/26.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class WhenToGoViewModel: ObservableObject {

    @Published var selectedMonthIndex: Int = 1 {
        didSet {
            recalculateForSelectedMonth()
        }
    }
    @Published var selectedCountry: WhenToGoItem? = nil

    @Published private(set) var countriesForSelectedMonth: [WhenToGoItem] = []

    private let weightsStore: ScoreWeightsStore

    private let allCountries: [Country]

    init(countries: [Country], weightsStore: ScoreWeightsStore) {
        self.allCountries = countries
        self.weightsStore = weightsStore
        recalculateForSelectedMonth()
    }

    var peakCountries: [WhenToGoItem] {
        countriesForSelectedMonth
            .filter { $0.seasonType == .peak }
            .sorted {
                weightedScore(for: $0.country) >
                weightedScore(for: $1.country)
            }
    }

    var shoulderCountries: [WhenToGoItem] {
        countriesForSelectedMonth
            .filter { $0.seasonType == .shoulder }
            .sorted {
                weightedScore(for: $0.country) >
                weightedScore(for: $1.country)
            }
    }

    var peakCount: Int { peakCountries.count }
    var shoulderCount: Int { shoulderCountries.count }
    var totalCount: Int { peakCount + shoulderCount }

    func recalculateForSelectedMonth() {
        countriesForSelectedMonth = allCountries.compactMap { country in
            guard let seasonType = computeSeasonType(for: country),
                  let seasonalityScore = computeSeasonalityScore(for: country)
            else { return nil }

            return WhenToGoItem(
                country: country,
                seasonType: seasonType,
                seasonalityScore: seasonalityScore
            )
        }
    }

    private func computeSeasonType(for country: Country) -> SeasonType? {
        guard let bestMonths = country.seasonalityBestMonths,
              !bestMonths.isEmpty,
              let score = country.seasonalityScore
        else { return nil }

        if bestMonths.contains(selectedMonthIndex) {
            return .peak
        }

        // If not peak but has a seasonality score, treat as shoulder
        if score > 0 {
            return .shoulder
        }

        return nil
    }

    private func computeSeasonalityScore(for country: Country) -> Int? {
        return country.seasonalityScore
    }

    private func weightedScore(for country: Country) -> Double {
        let weights = weightsStore.weights

        let advisory = Double(country.travelSafeScore ?? 50)
        let visa = Double(country.visaEaseScore ?? 50)

        let affordabilityRaw = country.dailySpendTotalUsd ?? 50
        let affordability = Double(min(max(affordabilityRaw, 0), 100))

        let weightedAdvisory = advisory * weights.advisory
        let weightedVisa = visa * weights.visa
        let weightedAffordability = affordability * weights.affordability

        let totalWeight =
            weights.advisory +
            weights.visa +
            weights.affordability

        let total =
            weightedAdvisory +
            weightedVisa +
            weightedAffordability

        let baseScore: Double = totalWeight > 0 ? total / totalWeight : 0

        guard let seasonalityScore = country.seasonalityScore else {
            return baseScore
        }

        // Subtle seasonality multiplier (0.9 – 1.1 range)
        let normalizedSeasonality = Double(seasonalityScore) / 100.0
        let modifier = 0.9 + (0.2 * normalizedSeasonality)

        return baseScore * modifier
    }
}
