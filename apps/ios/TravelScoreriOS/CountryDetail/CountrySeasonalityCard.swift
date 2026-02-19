//
//  CountrySeasonalityCard.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 2/15/26.
//

import Foundation
import SwiftUI

struct CountrySeasonalityCard: View {
    let country: Country

    var body: some View {
        if let seasonalityScore = country.seasonalityScore {
            VStack(alignment: .leading, spacing: 12) {

                // Title row
                HStack {
                    Text("Seasonality")
                        .font(.headline)
                    Spacer()
                    Text("Today · 5%")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                // Score pill + description
                HStack(spacing: 12) {
                    Text("\(seasonalityScore)")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(CountryScoreStyling.backgroundColor(for: seasonalityScore))
                        )
                        .overlay(
                            Capsule()
                                .stroke(CountryScoreStyling.borderColor(for: seasonalityScore), lineWidth: 1)
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        Text(CountrySeasonalityHelpers.headline(for: country))
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        Text(CountrySeasonalityHelpers.body(for: country))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                // Best months chips
                if let months = country.seasonalityBestMonths, !months.isEmpty {
                    HStack(spacing: 6) {
                        Text("Best months:")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        ForEach(months, id: \.self) { month in
                            Text(CountrySeasonalityHelpers.shortMonthName(for: month))
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule()
                                        .fill(Color.secondary.opacity(0.1))
                                )
                        }
                    }
                }

                HStack(spacing: 12) {
                    Text("Normalized: \(seasonalityScore)")
                    Text("Weight: 5%")
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                Text("Seasonality insights are based on historical climate averages and typical travel patterns. Timing may vary year to year.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }
}
