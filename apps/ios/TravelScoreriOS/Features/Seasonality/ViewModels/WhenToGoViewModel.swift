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

    private var cancellables = Set<AnyCancellable>()

    init(countries: [Country], weightsStore: ScoreWeightsStore) {
        self.allCountries = countries
        self.weightsStore = weightsStore
        weightsStore.$weights
            .sink { [weak self] _ in
                self?.recalculateForSelectedMonth()
            }
            .store(in: &cancellables)
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
        countriesForSelectedMonth = allCountries.compactMap { country -> WhenToGoItem? in
            guard let seasonType = computeSeasonType(for: country),
                  let seasonalityScore = computeSeasonalityScore(for: country)
            else { return nil }

            // Create a month-adjusted copy so UI reflects the selected month
            var adjustedCountry = country

            let computedOverall = weightedScore(for: adjustedCountry)
            adjustedCountry.score = Int(computedOverall.rounded())

            return WhenToGoItem(
                country: adjustedCountry,
                seasonType: seasonType,
                seasonalityScore: seasonalityScore
            )
        }
    }

    private func computeSeasonType(for country: Country) -> SeasonType? {
        guard let bestMonths = country.seasonalityBestMonths,
              !bestMonths.isEmpty
        else { return nil }

        if bestMonths.contains(selectedMonthIndex) {
            return .peak
        }

        // If not peak but country has some seasonality data, treat as shoulder
        if country.seasonalityScore ?? 0 > 0 {
            return .shoulder
        }

        return nil
    }

    private func computeSeasonalityScore(for country: Country) -> Int? {
        guard let bestMonths = country.seasonalityBestMonths,
              !bestMonths.isEmpty
        else { return nil }

        // If selected month is a best month, treat as strong seasonality
        if bestMonths.contains(selectedMonthIndex) {
            return 100
        }

        // Otherwise treat as off-season (0)
        return 0
    }

    private func weightedScore(for country: Country) -> Double {
        let weights = weightsStore.weights

        var components: [(value: Double, weight: Double)] = []

        if let advisory = country.travelSafeScore {
            components.append((Double(advisory), weights.advisory))
        }

        if let visa = country.visaEaseScore {
            components.append((Double(visa), weights.visa))
        }

        if let affordabilityScore = country.affordabilityScore {
            components.append((Double(affordabilityScore), weights.affordability))
        }

        let baseScore: Double
        if components.isEmpty {
            baseScore = 0
        } else {
            let totalWeight = components.reduce(0) { $0 + $1.weight }
            let weightedSum = components.reduce(0) { $0 + ($1.value * $1.weight) }
            baseScore = totalWeight > 0 ? weightedSum / totalWeight : 0
        }

        guard let seasonalityScore = country.seasonalityScore else {
            return baseScore
        }

        // Subtle seasonality multiplier (0.9 – 1.1 range)
        let normalizedSeasonality = Double(seasonalityScore) / 100.0
        let modifier = 0.9 + (0.2 * normalizedSeasonality)

        return baseScore * modifier
    }
}
