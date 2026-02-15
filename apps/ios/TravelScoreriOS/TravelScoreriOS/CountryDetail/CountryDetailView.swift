//
//  CountryDetailView.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 11/11/25.
//

import SwiftUI

struct CountryDetailView: View {
    @State var country: Country
    @EnvironmentObject private var profileVM: ProfileViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {

                CountryHeaderCard(country: country)
                    .padding(.horizontal)

                CountryAdvisoryCard(country: country)
                    .padding(.horizontal)
                
                CountryTravelSafeCard(country: country)
                    .padding(.horizontal)

                CountrySeasonalityCard(country: country)
                    .padding(.horizontal)

                CountryVisaCard(country: country)
                    .padding(.horizontal)

                // You can add more sections later: Reddit sentiment, TravelSafe, Solo Female Travel, etc.
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .padding(.vertical, 16)
        }
        .navigationTitle(country.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let id = SupabaseManager.shared.currentUserId {
                profileVM.setUserIdIfNeeded(id)
            }
        }
    }

    // MARK: - Factor helpers
    
}

#Preview {
    NavigationStack {
        CountryDetailView(
            country: Country(
                iso2: "JP",
                name: "Japan",
                score: 90,
                region: "Asia",
                subregion: "East Asia",
                advisoryLevel: "Level 1"
            )
        )
    }
}
