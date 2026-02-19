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

    @Published var selectedMonthIndex: Int = 1 // 0=Jan, 1=Feb, ...
    @Published var selectedCountry: WhenToGoCountry? = nil

    // Replace this with your real fetched data for the selected month.
    @Published var countriesForSelectedMonth: [WhenToGoCountry] = []

    var peakCountries: [WhenToGoCountry] {
        countriesForSelectedMonth
            .filter { $0.seasonType == .peak }
            .sorted { $0.score > $1.score }
    }

    var shoulderCountries: [WhenToGoCountry] {
        countriesForSelectedMonth
            .filter { $0.seasonType == .shoulder }
            .sorted { $0.score > $1.score }
    }

    var peakCount: Int { peakCountries.count }
    var shoulderCount: Int { shoulderCountries.count }
    var totalCount: Int { peakCount + shoulderCount }

    func loadMockDataIfNeeded() {
        guard countriesForSelectedMonth.isEmpty else { return }

        // MOCK (so you can see UI immediately). Replace with real fetch.
        countriesForSelectedMonth = [
            .init(id: "qatar", name: "Qatar", region: "Asia", score: 97, seasonType: .peak, slug: "qatar"),
            .init(id: "singapore", name: "Singapore", region: "Asia", score: 94, seasonType: .peak, slug: "singapore"),
            .init(id: "suriname", name: "Suriname", region: "Americas", score: 97, seasonType: .shoulder, slug: "suriname"),
            .init(id: "kenya", name: "Kenya", region: "Africa", score: 69, seasonType: .shoulder, slug: "kenya")
        ]
    }
}
