//
//  MyTravelsView.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 1/24/26.
//

import SwiftUI

struct MyTravelsView: View {
    @EnvironmentObject private var traveled: TraveledStore
    @State private var countries: [Country] = []

    private var visitedCountries: [Country] {
        countries
            .filter { traveled.ids.contains($0.id) }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    var body: some View {
        Group {
            if visitedCountries.isEmpty {
                ContentUnavailableView(
                    "No trips yet",
                    systemImage: "backpack",
                    description: Text("Swipe left on a country and tap 📝 Visited to track places you’ve already been.")
                )
            } else {
                List(visitedCountries) { country in
                    NavigationLink(value: country) {
                        HStack(spacing: 12) {
                            Text(country.flagEmoji)
                                .font(.largeTitle)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(country.name)
                                    .font(.headline)

                                if let adv = country.advisoryLevel {
                                    Text(adv)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Spacer()

                            ScorePill(score: country.score)
                        }
                        .padding(.vertical, 6)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("🎒 My Travels")
        .navigationDestination(for: Country.self) { country in
            CountryDetailView(country: country)
        }
        .task {
            guard countries.isEmpty else { return }
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
    NavigationStack {
        MyTravelsView()
            .environmentObject(TraveledStore())
    }
}
