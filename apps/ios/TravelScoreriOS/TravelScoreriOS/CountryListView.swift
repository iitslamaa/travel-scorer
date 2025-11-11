//
//  CountryListView.swift.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 11/10/25.
//

import SwiftUI

struct CountryListView: View {
    @State private var sort: CountrySort = .name
    @State private var search = ""
    @State private var countries: [Country] = []

    private var filteredAndSorted: [Country] {
        let filtered = countries.filter {
            search.isEmpty || $0.name.localizedCaseInsensitiveContains(search)
        }
        switch sort {
        case .name:  return filtered.sorted { $0.name  < $1.name }
        case .score: return filtered.sorted { $0.score > $1.score }
        }
    }

    var body: some View {
        List(filteredAndSorted) { country in
            NavigationLink(value: country) {
                HStack(spacing: 12) {
                    Text(country.flagEmoji).font(.largeTitle)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(country.name).font(.headline)
                        if let adv = country.advisoryLevel {
                            Text(adv).font(.subheadline).foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    ScorePill(score: country.score)
                }
                .padding(.vertical, 6)
            }
        }
        .listStyle(.plain)
        .searchable(text: $search, prompt: "Search countries")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Picker("Sort", selection: $sort) {
                    ForEach(CountrySort.allCases, id: \.self) { s in
                        Text(s.rawValue).tag(s)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 220)
            }
        }
        .navigationTitle("TravelAF")
        // Load from API, fall back to bundled JSON if API fails
        .task {
            do {
                let apiCountries = try await CountryAPI.fetchCountries()
                if !apiCountries.isEmpty {
                    countries = apiCountries
                } else {
                    countries = DataLoader.loadCountriesFromBundle()
                }
            } catch {
                print("Failed to load countries:", error)
                countries = DataLoader.loadCountriesFromBundle()
            }
        }
    }
}

#Preview {
    CountryListView()
}
