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
    let countries: [Country]
    @Binding var sort: CountrySort
    @Binding var sortOrder: SortOrder

    init(
        showsSearchBar: Bool = true,
        searchText: String = "",
        countries: [Country],
        sort: Binding<CountrySort>,
        sortOrder: Binding<SortOrder>
    ) {
        self.showsSearchBar = showsSearchBar
        self.searchText = searchText
        self.countries = countries
        self._sort = sort
        self._sortOrder = sortOrder
    }

    @EnvironmentObject private var sessionManager: SessionManager
    @EnvironmentObject private var weightsStore: ScoreWeightsStore

    @State private var visibleCountries: [Country] = []
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

            // Weighted score recompute (exclude missing metrics)
            var components: [(value: Double, weight: Double)] = []

            if let advisory = country.travelSafeScore {
                components.append((Double(advisory), weights.advisory))
            }

            if let visa = country.visaEaseScore {
                components.append((Double(visa), weights.visa))
            }

            if let affordabilityRaw = country.dailySpendTotalUsd {
                let affordability = Double(min(max(affordabilityRaw, 0), 100))
                components.append((affordability, weights.affordability))
            }

            if components.isEmpty {
                updated.score = nil
            } else {
                let totalWeight = components.reduce(0) { $0 + $1.weight }
                let weightedSum = components.reduce(0) { $0 + ($1.value * $1.weight) }

                if totalWeight > 0 {
                    let normalizedScore = weightedSum / totalWeight
                    updated.score = Int(normalizedScore.rounded())
                } else {
                    updated.score = nil
                }
            }
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
                baseSorted = filtered.sorted { ($0.score ?? Int.min) < ($1.score ?? Int.min) }
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
                    }
                    Spacer()

                    HStack(spacing: 8) {
                        if let score = country.score {
                            ScorePill(score: score)
                        } else {
                            Text("—")
                                .font(.caption.bold())
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color.gray.opacity(0.15))
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                        }

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
        .listStyle(.plain)
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
        .onAppear {
            scheduleRecomputeVisible()
        }
        .onChange(of: countries) { _, _ in
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
    CountryListView(showsSearchBar: true, searchText: "", countries: [], sort: .constant(.name), sortOrder: .constant(.descending))
}
