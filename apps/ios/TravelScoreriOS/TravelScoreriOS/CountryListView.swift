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
    @State private var hasLoaded = false

    // MARK: - Quick swipe confirmation (brief checkmark)

    private enum QuickConfirm {
        case bucket
        case visited
    }

    @State private var quickConfirmByCountryId: [String: QuickConfirm] = [:]

    private func flashConfirm(_ type: QuickConfirm, for id: String) {
        quickConfirmByCountryId[id] = type
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            if quickConfirmByCountryId[id] == type {
                quickConfirmByCountryId[id] = nil
            }
        }
    }

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
            baseSorted = filtered.sorted(by: { (a: Country, b: Country) -> Bool in
                a.score < b.score
            })
        }

        switch sortOrder {
        case .ascending:
            return baseSorted
        case .descending:
            return Array(baseSorted.reversed())
        }
    }

    var body: some View {
        List(filteredAndSorted, id: \.id) { country in
            let idStr = country.id
            let showConfirm = quickConfirmByCountryId[idStr] != nil

            NavigationLink {
                CountryDetailView(country: country)
            } label: {
                HStack(spacing: 12) {
                    Text(country.flagEmoji).font(.largeTitle)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(country.name).font(.headline)
                        if let adv = country.advisoryLevel {
                            Text(adv).font(.subheadline).foregroundStyle(.secondary)
                        }
                    }
                    Spacer()

                    HStack(spacing: 8) {
                        ScorePill(score: country.score)

                        ZStack {
                            // invisible placeholder to keep layout stable
                            Image(systemName: "checkmark.circle.fill")
                                .opacity(0)
                        }
                        .frame(width: 22, height: 22)
                        .overlay {
                            if showConfirm {
                                Image(systemName: "checkmark.circle.fill")
                                    .transition(.opacity)
                            }
                        }
                        .animation(.easeInOut(duration: 0.18), value: showConfirm)
                    }
                }
                .padding(.vertical, 6)
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button {
                        bucketList.toggle(idStr)
                        flashConfirm(.bucket, for: idStr)
                    } label: {
                        Text(bucketList.contains(idStr) ? "🪣 Unbucket" : "🪣 Bucket")
                    }
                    .tint(.blue)

                    Button {
                        traveled.toggle(idStr)
                        flashConfirm(.visited, for: idStr)
                    } label: {
                        Text(traveled.contains(idStr) ? "📝 Unvisit" : "📝 Visited")
                    }
                    .tint(.green)
                }
            }
        }
        .listStyle(.plain)
        .searchable(text: $search, prompt: Text("Search countries"))
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
        .navigationTitle("Travel AF")
        .onAppear {
            guard !hasLoaded else { return }
            hasLoaded = true

            // 1) Show cached data immediately (fast/offline)
            if let cached = CountryAPI.loadCachedCountries(), !cached.isEmpty {
                countries = cached
            }

            Task {
                // 2) Try to refresh from API (skips if refreshed recently)
                if let fresh = await CountryAPI.refreshCountriesIfNeeded(minInterval: 60),
                   !fresh.isEmpty {
                    await MainActor.run {
                        countries = fresh
                    }
                    return
                }

                // 3) If we still have nothing, fall back to bundled data
                if countries.isEmpty {
                    await MainActor.run {
                        countries = DataLoader.loadCountriesFromBundle()
                    }
                }
            }
        }
    }
}

#Preview {
    CountryListView()
}
