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

                if let category = country.affordabilityCategory,
                   let score = country.affordabilityScore {

                    CountryScoreSection(
                        title: "Affordability",
                        weight: weightsStore.affordabilityPercentage,
                        score: score,
                        band: nil, // force legacy styling for CountryDetailView only
                        headline: labelForAffordability(category),
                        subtitle: "Category \(category)/10"
                    )
                    .padding(.horizontal)
                }

                // You can add more sections later: Reddit sentiment, TravelSafe, Solo Female Travel, etc.
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .padding(.vertical, 16)
        }
        .navigationTitle(country.name)
        .navigationBarTitleDisplayMode(.inline)
    }
    private func labelForAffordability(_ category: Int) -> String {
        switch category {
        case 1: return "Extremely Affordable"
        case 2: return "Very Affordable"
        case 3: return "Affordable"
        case 4: return "Budget-Friendly"
        case 5: return "Moderate"
        case 6: return "Slightly Expensive"
        case 7: return "Expensive"
        case 8: return "Very Expensive"
        case 9: return "Premium"
        case 10: return "Very Premium"
        default: return "Unknown"
        }
    }
}
