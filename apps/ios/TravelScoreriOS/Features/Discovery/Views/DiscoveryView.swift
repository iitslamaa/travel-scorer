//
//  DiscoveryView.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 2/9/26.
//

import SwiftUI

struct DiscoveryView: View {

    @State private var searchText = ""
    @State private var showingWeights = false

    var body: some View {
        ZStack {

            // Scrollable content (countries only)
            CountryListView(
                showsSearchBar: false,
                searchText: searchText
            )

        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    showingWeights = true
                } label: {
                    Image(systemName: "slider.horizontal.3")
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
        .background(.ultraThinMaterial)
        .shadow(radius: 6)
        .padding(.top, 6)
    }
}

#Preview {
    NavigationStack {
        DiscoveryView()
    }
}
