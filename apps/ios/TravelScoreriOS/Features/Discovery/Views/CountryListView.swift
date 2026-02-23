//
//  CountryListView.swift.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 11/10/25.
//


import SwiftUI
import Supabase
import PostgREST

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
    let showsSearchBar: Bool
    let searchText: String

    init(showsSearchBar: Bool = true, searchText: String = "") {
        self.showsSearchBar = showsSearchBar
        self.searchText = searchText
    }

    @EnvironmentObject private var sessionManager: SessionManager
    @EnvironmentObject private var weightsStore: ScoreWeightsStore

    @State private var sort: CountrySort = .name
    @State private var sortOrder: SortOrder = .descending
    @State private var countries: [Country] = []
    @State private var visibleCountries: [Country] = []
    @State private var hasLoaded = false
    @State private var bucketCountryIds: Set<String> = []
    @State private var traveledCountryIds: Set<String> = []

    // Keep a handle to the latest recompute task so we can cancel stale work
    @State private var recomputeTask: Task<Void, Never>?

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

    private func scheduleRecomputeVisible() {
        // Cancel any in-flight recompute so fast typing / toggling doesn't queue work.
        recomputeTask?.cancel()

        // Recalculate scores using current weights
        var recalculatedCountries: [Country] = []
        let weights = weightsStore.weights

        for country in countries {
            var updated = country

            // Simple 4-factor weighted score recompute
            let advisory = country.travelSafeScore ?? 50
            let seasonality = country.seasonalityScore ?? 50
            let visa = country.visaEaseScore ?? 50

            // Normalize affordability roughly to 0–100 range (fallback 50)
            let affordabilityRaw = country.dailySpendTotalUsd ?? 50
            let affordability = min(max(affordabilityRaw, 0), 100)

            let weightedAdvisory = Double(advisory) * weights.advisory
            let weightedSeasonality = Double(seasonality) * weights.seasonality
            let weightedVisa = Double(visa) * weights.visa
            let weightedAffordability = Double(affordability) * weights.affordability

            let totalWeight =
                weights.advisory +
                weights.seasonality +
                weights.visa +
                weights.affordability

            let total =
                weightedAdvisory +
                weightedSeasonality +
                weightedVisa +
                weightedAffordability

            let normalizedScore: Double
            if totalWeight > 0 {
                normalizedScore = total / totalWeight
            } else {
                normalizedScore = 0
            }

            updated.score = Int(normalizedScore.rounded())
            recalculatedCountries.append(updated)
        }

        // Capture a snapshot of inputs to process off-main.
        let snapshotCountries = recalculatedCountries
        let snapshotSearch = searchText
        let snapshotSort = sort
        let snapshotSortOrder = sortOrder

        recomputeTask = Task.detached(priority: .userInitiated) {
            // Filter
            let filtered: [Country]
            if snapshotSearch.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                filtered = snapshotCountries
            } else {
                filtered = snapshotCountries.filter { $0.name.localizedCaseInsensitiveContains(snapshotSearch) }
            }

            // Sort
            let baseSorted: [Country]
            switch snapshotSort {
            case .name:
                baseSorted = filtered.sorted {
                    $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
                }
            case .score:
                // Sort ascending, then flip based on order
                baseSorted = filtered.sorted { $0.score < $1.score }
            }

            let result: [Country]
            switch snapshotSortOrder {
            case .ascending:
                result = baseSorted
            case .descending:
                result = Array(baseSorted.reversed())
            }

            // Publish back on main
            await MainActor.run {
                // If this task was cancelled, don't apply.
                if Task.isCancelled { return }
                self.visibleCountries = result
            }
        }
    }

    var body: some View {
        List(visibleCountries, id: \.id) { country in
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
                        Task {
                            if let userId = sessionManager.userId {
                                let service = ProfileService(supabase: SupabaseManager.shared)
                                if bucketCountryIds.contains(idStr) {
                                    try? await service.removeFromBucketList(userId: userId, countryCode: idStr)
                                    bucketCountryIds.remove(idStr)
                                } else {
                                    try? await service.addToBucketList(userId: userId, countryCode: idStr)
                                    bucketCountryIds.insert(idStr)
                                }
                                flashConfirm(.bucket, for: idStr)
                            }
                        }
                    } label: {
                        Text(
                            bucketCountryIds.contains(idStr)
                            ? "🪣 Unbucket"
                            : "🪣 Bucket"
                        )
                    }
                    .tint(.blue)

                    Button {
                        Task {
                            if let userId = sessionManager.userId {
                                let client = SupabaseManager.shared.client
                                if traveledCountryIds.contains(idStr) {
                                    try? await client
                                        .from("user_traveled")
                                        .delete()
                                        .eq("user_id", value: userId.uuidString)
                                        .eq("country_id", value: idStr)
                                        .execute()
                                    traveledCountryIds.remove(idStr)
                                } else {
                                    try? await client
                                        .from("user_traveled")
                                        .insert(["user_id": userId.uuidString, "country_id": idStr])
                                        .execute()
                                    traveledCountryIds.insert(idStr)
                                }
                                flashConfirm(.visited, for: idStr)
                            }
                        }
                    } label: {
                        Text(
                            traveledCountryIds.contains(idStr)
                            ? "📝 Unvisit"
                            : "📝 Visited"
                        )
                    }
                    .tint(.green)
                }
            }
        }
        .refreshable {
            do {
                // Always attempt a refresh, but never block the UI indefinitely
                if let fresh = await CountryAPI.refreshCountriesIfNeeded(minInterval: 0),
                   !fresh.isEmpty {
                    countries = fresh

                    // Recompute visible list once, after refresh completes
                    DispatchQueue.main.async {
                        scheduleRecomputeVisible()
                    }
                }
            } catch {
                // Swallow errors so the refresh control always ends
                print("🔴 Pull-to-refresh failed, keeping cached data:", error)
            }
        }
        .listStyle(.plain)
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

                    // 🗺️ Score Map button
                    NavigationLink {
                        ScoreWorldMapView(countries: countries)
                    } label: {
                        Text("🗺️")
                    }
                }
            }
        }
        .task {
            guard !hasLoaded else { return }
            hasLoaded = true

            // 1) Show cached data immediately (fast/offline)
            if let cached = CountryAPI.loadCachedCountries(), !cached.isEmpty {
                countries = cached
                scheduleRecomputeVisible()
            }

            // 2) Refresh from API (skips if refreshed recently)
            if let fresh = await CountryAPI.refreshCountriesIfNeeded(minInterval: 60),
               !fresh.isEmpty {
                countries = fresh
                scheduleRecomputeVisible()
                return
            }

            // Fetch identity-scoped bucket + traveled state
            if let userId = sessionManager.userId {
                let service = ProfileService(supabase: SupabaseManager.shared)
                if let bucket = try? await service.fetchBucketListCountries(userId: userId) {
                    bucketCountryIds = bucket
                }
                if let traveled = try? await service.fetchTraveledCountries(userId: userId) {
                    traveledCountryIds = traveled
                }
            }
        }
        // Recompute visible list when inputs change
        .onChange(of: searchText) { _, _ in
            scheduleRecomputeVisible()
        }
        .onChange(of: sort) { _, _ in
            scheduleRecomputeVisible()
        }
        .onChange(of: sortOrder) { _, _ in
            scheduleRecomputeVisible()
        }
        .onChange(of: countries.count) { _, _ in
            scheduleRecomputeVisible()
        }
    }
}

extension View {
    @ViewBuilder
    func `if`<Content: View>(
        _ condition: Bool,
        transform: (Self) -> Content
    ) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

#Preview {
    CountryListView(showsSearchBar: true, searchText: "")
}
