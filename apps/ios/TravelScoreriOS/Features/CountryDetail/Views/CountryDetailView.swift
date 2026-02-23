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
                .padding(.horizontal)

                CountrySeasonalityCard(
                    country: country,
                    weightPercentage: 0
                )
                .padding(.horizontal)

                CountryVisaCard(
                    country: country,
                    weightPercentage: weightsStore.visaPercentage
                )
                .padding(.horizontal)

                if country.affordabilityScore != nil {
                    CountryAffordabilityCard(
                        country: country,
                        weightPercentage: weightsStore.affordabilityPercentage
                    )
                    .padding(.horizontal)
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .padding(.vertical, 16)
        }
        .navigationTitle(country.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
