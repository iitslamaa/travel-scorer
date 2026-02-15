//
//  BucketListView.swift
//  TravelScoreriOS
//

import SwiftUI

struct BucketListView: View {
    @EnvironmentObject private var profileVM: ProfileViewModel
    @State private var countries: [Country] = []

    private var bucketedCountries: [Country] {
        countries
            .filter { profileVM.viewedBucketListCountries.contains($0.id) }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    var body: some View {
        Group {
            if bucketedCountries.isEmpty {
                ContentUnavailableView(
                    "No Bucket List Yet",
                    systemImage: "bookmark",
                    description: Text("Swipe left on a country and tap 🪣 Bucket to save it here.")
                )
            } else {
                List(bucketedCountries) { country in
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
        .navigationTitle("🪣 Bucket List")
        .navigationDestination(for: Country.self) { country in
            CountryDetailView(country: country)
        }
        .task {
            // 1) Show cached data immediately (fast/offline)
            if let cached = CountryAPI.loadCachedCountries(), !cached.isEmpty {
                countries = cached
            }

            // 2) Try to refresh from API
            if let fresh = await CountryAPI.refreshCountriesIfNeeded(minInterval: 60), !fresh.isEmpty {
                countries = fresh
            }

            // DEBUG PRINTS
            print("🟢 Bucket ISO codes:", profileVM.orderedBucketListCountries)
            print("🟢 First 20 Country IDs from dataset:", countries.map { $0.id }.prefix(20))
            print("🟢 All dataset IDs:", countries.map { $0.id })

            // 3) Fallback to bundled data
            if countries.isEmpty {
                countries = DataLoader.loadCountriesFromBundle()
            }
        }
    }
}

#Preview {
    NavigationStack {
        BucketListView()
            .environmentObject(ProfileViewModel(profileService: ProfileService(supabase: SupabaseManager.shared)))
    }
}
