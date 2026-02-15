//
//  MyTravelsView.swift
//  TravelScoreriOS
//

import SwiftUI

struct MyTravelsView: View {
    @EnvironmentObject private var profileVM: ProfileViewModel
    @State private var countries: [Country] = []

    private var visitedCountries: [Country] {
        countries
            .filter { profileVM.orderedTraveledCountries.contains($0.id) }
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
            // Ensure profileVM is bound to current user
            if let id = SupabaseManager.shared.currentUserId {
                profileVM.setUserIdIfNeeded(id)
            }

            // 1) Show cached data immediately (fast/offline)
            if let cached = CountryAPI.loadCachedCountries(), !cached.isEmpty {
                countries = cached
            }

            // 2) Try to refresh from API
            if let fresh = await CountryAPI.refreshCountriesIfNeeded(minInterval: 60), !fresh.isEmpty {
                countries = fresh
                return
            }

            // 3) Fallback to bundled data
            if countries.isEmpty {
                countries = DataLoader.loadCountriesFromBundle()
            }
        }
    }
}

#Preview {
    NavigationStack {
        MyTravelsView()
            .environmentObject(
                ProfileViewModel(
                    profileService: ProfileService(supabase: SupabaseManager.shared)
                )
            )
    }
}
