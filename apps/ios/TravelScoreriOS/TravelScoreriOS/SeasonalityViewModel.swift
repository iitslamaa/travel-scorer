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
            await load(forMonth: selectedMonth)
        }
    }

    func load(forMonth month: Int) async {
        isLoading = true
        loadError = nil

        do {
            let response = try await service.fetchSeasonality(forMonth: month)
            selectedMonth = response.month
            peakCountries = response.peak
            shoulderCountries = response.shoulder

            // Reset selection when month changes
            if let first = response.peak.first {
                selectedCountry = first
            } else {
                selectedCountry = response.shoulder.first
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
