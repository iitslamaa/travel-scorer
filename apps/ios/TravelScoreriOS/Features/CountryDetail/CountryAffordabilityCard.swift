//
//  CountryAffordabilityCard.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 2/23/26.
//

import Foundation
import SwiftUI

struct CountryAffordabilityCard: View {
    let country: Country
    let weightPercentage: Int

    var body: some View {
        if let affordabilityScore = country.affordabilityScore {
            VStack(alignment: .leading, spacing: 12) {

                // Title row
                HStack {
                    Text("Affordability")
                        .font(.headline)
                    Spacer()
                    Text("Estimated daily cost · \(weightPercentage)%")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                // Score pill + description
                HStack(spacing: 12) {

                    Text("\(affordabilityScore)")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(CountryScoreStyling.backgroundColor(for: affordabilityScore))
                        )
                        .overlay(
                            Capsule()
                                .stroke(
                                    CountryScoreStyling.borderColor(for: affordabilityScore),
                                    lineWidth: 1
                                )
                        )

                    VStack(alignment: .leading, spacing: 4) {

                        if let headline = country.affordabilityHeadline {
                            Text(headline)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }

                        if let body = country.affordabilityBody {
                            Text(body)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }

                // Optional daily spend breakdown (if available)
                VStack(alignment: .leading, spacing: 4) {

                    if let total = country.dailySpendTotalUsd {
                        Text(String(format: "Typical daily total: $%.0f USD", total))
                    }

                    if let hotel = country.dailySpendHotelUsd {
                        Text(String(format: "Hotel (per night): $%.0f USD", hotel))
                    }

                    if let food = country.dailySpendFoodUsd {
                        Text(String(format: "Food (per day): $%.0f USD", food))
                    }

                    if let activities = country.dailySpendActivitiesUsd {
                        Text(String(format: "Activities (per day): $%.0f USD", activities))
                    }
                }
                .font(.footnote)
                .foregroundStyle(.secondary)

                // Footer
                HStack(spacing: 12) {
                    Text("Normalized: \(affordabilityScore)")
                    Text("Weight: \(weightPercentage)%")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }
}
