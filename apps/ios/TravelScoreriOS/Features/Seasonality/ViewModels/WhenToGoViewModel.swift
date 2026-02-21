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

    private let allCountries: [Country]

    init(countries: [Country]) {
        self.allCountries = countries
        recalculateForSelectedMonth()
    }

    var peakCountries: [WhenToGoItem] {
        countriesForSelectedMonth
            .filter { $0.seasonType == .peak }
            .sorted { $0.seasonalityScore > $1.seasonalityScore }
    }

    var shoulderCountries: [WhenToGoItem] {
        countriesForSelectedMonth
            .filter { $0.seasonType == .shoulder }
            .sorted { $0.seasonalityScore > $1.seasonalityScore }
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
}
