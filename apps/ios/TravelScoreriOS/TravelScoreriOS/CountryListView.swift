//
//  CountryListView.swift.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 11/10/25.
//

import SwiftUI

enum SortOrder {
    case ascending
    case descending
}

struct MapPlaceholderView: View {
    var body: some View {
        NavigationStack {
            Text("Global map view coming soon 🌍")
                .navigationTitle("Map")
        }
    }
}

struct CountryListView: View {
    @EnvironmentObject private var bucketList: BucketListStore
    @EnvironmentObject private var traveled: TraveledStore

    @State private var sort: CountrySort = .name
    @State private var sortOrder: SortOrder = .descending
    @State private var search = ""
    @State private var countries: [Country] = []
    @State private var showingMap = false

    private var filteredAndSorted: [Country] {
        let filtered = countries.filter {
            search.isEmpty || $0.name.localizedCaseInsensitiveContains(search)
        }

        let baseSorted: [Country]
        switch sort {
        case .name:
            baseSorted = filtered.sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
        case .score:
            baseSorted = filtered.sorted { $0.score < $1.score }
        }

        switch sortOrder {
        case .ascending:
            return baseSorted
        case .descending:
            return Array(baseSorted.reversed())
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
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button {
                        bucketList.toggle(country.id)
                    } label: {
                        Text(bucketList.contains(country.id) ? "🪣 Unbucket" : "🪣 Bucket")
                    }
                    .tint(.blue)

                    Button {
                        traveled.toggle(country.id)
                    } label: {
                        Text(traveled.contains(country.id) ? "📝 Unvisit" : "📝 Visited")
                    }
                    .tint(.green)
                }
            }
        }
        .listStyle(.plain)
        .searchable(text: $search, prompt: "Search countries")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 12) {
                    // Sort picker
                    Picker("Sort", selection: $sort) {
                        ForEach(CountrySort.allCases, id: \.self) { s in
                            Text(s.rawValue).tag(s)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 180)

                    // Sort order button
                    Button {
                        sortOrder = (sortOrder == .ascending) ? .descending : .ascending
                    } label: {
                        Image(systemName: sortOrder == .ascending ? "arrow.up" : "arrow.down")
                    }

                    // 🗺️ Map button (future global map view)
                    Button {
                        showingMap = true
                    } label: {
                        Text("🗺️")
                    }
                }
            }
        }
        .sheet(isPresented: $showingMap) {
            MapPlaceholderView()
        }
        .navigationDestination(for: Country.self) { country in
            CountryDetailView(country: country)
        }
        .navigationTitle("TravelAF")
        .task {
            // 1) Show cached data immediately (fast/offline)
            if let cached = CountryAPI.loadCachedCountries(), !cached.isEmpty {
                countries = cached
            }

            // 2) Try to refresh from API (skips if refreshed recently)
            if let fresh = await CountryAPI.refreshCountriesIfNeeded(minInterval: 60), !fresh.isEmpty {
                countries = fresh
                return
            }

            // 3) If we still have nothing, fall back to bundled data
            if countries.isEmpty {
                countries = DataLoader.loadCountriesFromBundle()
            }
        }
    }
}

#Preview {
    CountryListView()
}
