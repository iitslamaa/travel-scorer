//
//  DiscoveryView.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 2/9/26.
//

import SwiftUI

struct DiscoveryView: View {

    @EnvironmentObject private var profileVM: ProfileViewModel

    @State private var searchText = ""
    @State private var showingWeights = false
    @State private var sort: CountrySort = .name
    @State private var sortOrder: SortOrder = .ascending
    @State private var countries: [Country] = []

    @MainActor
    private func reloadCountries() async {
        // Force reload from source instead of just recomputing locally
        if let fresh = CountryAPI.loadCachedCountries(), !fresh.isEmpty {
            countries = fresh
        }

        await profileVM.loadIfNeeded()
    }

    var body: some View {
        VStack(spacing: 0) {

            DiscoveryControlsView(
                sort: $sort,
                sortOrder: $sortOrder
            )
            .padding(.horizontal)
            .padding(.top, 8)

            CountryListView(
                showsSearchBar: false,
                searchText: searchText,
                countries: countries,
                sort: $sort,
                sortOrder: $sortOrder
            )
        }
        .refreshable {
            await reloadCountries()
        }
        .task {
            if countries.isEmpty {
                if let cached = CountryAPI.loadCachedCountries(), !cached.isEmpty {
                    countries = cached
                }
            }

            await profileVM.loadIfNeeded()
        }
        .navigationTitle("Discover")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // Filters (leading)
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    showingWeights = true
                } label: {
                    Image(systemName: "slider.horizontal.3")
                }
            }

            // Map (trailing)
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink {
                    ScoreWorldMapView(countries: countries)
                } label: {
                    Image(systemName: "map")
                }
            }
        }
        .sheet(isPresented: $showingWeights) {
            NavigationStack {
                CustomWeightsView()
            }
        }
        .safeAreaInset(edge: .bottom) {
            FloatingSearchBar(text: $searchText)
        }
    }
}

struct FloatingSearchBar: View {
    @Binding var text: String
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField("Search destinations by country or code", text: $text)
                    .focused($isFocused)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)

                if isFocused {
                    Button {
                        isFocused = false
                    } label: {
                        Image(systemName: "chevron.down")
                            .foregroundStyle(.secondary)
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.systemBackground))
            )
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .padding(.top, 10)
        .background(.ultraThinMaterial)
        .shadow(radius: 6)
        .padding(.top, 0)
    }
}

#Preview {
    NavigationStack {
        DiscoveryView()
    }
}
