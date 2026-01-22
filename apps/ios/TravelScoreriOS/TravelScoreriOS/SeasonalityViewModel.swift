//
//  SeasonalityViewModel.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 12/2/25.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class SeasonalityViewModel: ObservableObject {

    @Published var selectedMonth: Int
    @Published var peakCountries: [SeasonalityCountry]
    @Published var shoulderCountries: [SeasonalityCountry]
    @Published var selectedCountry: SeasonalityCountry?

    @Published var isLoading: Bool
    @Published var loadError: String?

    private let service: SeasonalityService

    private struct CountryMeta {
        let name: String
        let score: Double?
        let region: String?
    }

    private var countryMetaByISO: [String: CountryMeta] = [:]

    init(
        service: SeasonalityService = SeasonalityService(),
        initialMonth: Int = Calendar.current.component(.month, from: Date())
    ) {
        self.service = service
        self.selectedMonth = initialMonth
        self.peakCountries = []
        self.shoulderCountries = []
        self.selectedCountry = nil
        self.isLoading = false
        self.loadError = nil
    }

    func loadInitial() {
        Task {
            await loadCountryMetaIfNeeded()
            await load(forMonth: selectedMonth)
        }
    }

    private func loadCountryMetaIfNeeded() async {
        // Only fetch once per app session for this view model instance
        if !countryMetaByISO.isEmpty { return }

        do {
            let countries = try await CountryAPI.fetchCountries()
            var map: [String: CountryMeta] = [:]
            for c in countries {
                // Country model uses `iso2` in this codebase (see CountryAPI mapping)
                let iso = c.iso2.uppercased()
                map[iso] = CountryMeta(
                    name: c.name,
                    score: {
                        // In this codebase, `Country.score` may be an `Int` (or optional). Convert to Double for UI.
                        if let s = c.score as? Double { return s }
                        if let s = c.score as? Int { return Double(s) }
                        if let s = c.score as? Int? { return s.map(Double.init) }
                        if let s = c.score as? Double? { return s }
                        return nil
                    }(),
                    region: c.region
                )
            }
            countryMetaByISO = map
        } catch {
            // Non-fatal: seasonality can still render with ISO codes.
            // Keep loadError reserved for seasonality endpoint failures.
            print("⚠️ [SeasonalityViewModel] Failed to load country metadata:", error)
        }
    }

    private func enrich(_ list: [SeasonalityCountry]) -> [SeasonalityCountry] {
        guard !countryMetaByISO.isEmpty else { return list }

        return list.map { c in
            let iso = c.isoCode.uppercased()
            if let meta = countryMetaByISO[iso] {
                return SeasonalityCountry(
                    isoCode: c.isoCode,
                    name: meta.name,
                    score: meta.score ?? c.score,
                    region: meta.region ?? c.region,
                    advisoryLevel: c.advisoryLevel,
                    scores: c.scores
                )
            }
            // Fallback: keep whatever came from the seasonality endpoint
            return c
        }
    }

    func load(forMonth month: Int) async {
        isLoading = true
        loadError = nil

        do {
            // Ensure we have country names/scores to display
            await loadCountryMetaIfNeeded()

            let response = try await service.fetchSeasonality(forMonth: month)
            selectedMonth = response.month

            let enrichedPeak = enrich(response.peak)
            let enrichedShoulder = enrich(response.shoulder)

            peakCountries = enrichedPeak
            shoulderCountries = enrichedShoulder

            // Reset selection when month changes
            if let first = enrichedPeak.first {
                selectedCountry = first
            } else {
                selectedCountry = enrichedShoulder.first
            }
        } catch {
            loadError = error.localizedDescription
        }

        isLoading = false
    }

    func select(_ country: SeasonalityCountry) {
        selectedCountry = country
    }
}
