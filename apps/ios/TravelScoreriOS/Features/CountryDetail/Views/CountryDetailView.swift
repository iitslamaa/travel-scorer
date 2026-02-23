//
//  CountryDetailView.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 11/11/25.
//

import SwiftUI

struct CountryDetailView: View {
    private let isTravelSafetyEnabled = false
    @State var country: Country
    @EnvironmentObject private var weightsStore: ScoreWeightsStore

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {

                CountryHeaderCard(country: country)
                    .padding(.horizontal)

                CountryAdvisoryCard(
                    country: country,
                    weightPercentage: weightsStore.advisoryPercentage
                )

                CountrySeasonalityCard(
                    country: country,
                    weightPercentage: weightsStore.seasonalityPercentage
                )

                CountryVisaCard(
                    country: country,
                    weightPercentage: weightsStore.visaPercentage
                )

                // You can add more sections later: Reddit sentiment, TravelSafe, Solo Female Travel, etc.
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .padding(.vertical, 16)
        }
        .navigationTitle(country.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
