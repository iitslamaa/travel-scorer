//
//  CountryTravelSafeCard.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 2/15/26.
//

import Foundation
import SwiftUI

struct CountryTravelSafeCard: View {
    let country: Country

    var body: some View {
        if let safety = country.travelSafeScore {
            VStack(alignment: .leading, spacing: 12) {

                // Title row
                HStack {
                    Text("Travel safety")
                        .font(.headline)
                    Spacer()
                    Text("TravelSafe · 15%")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                // Score pill + description
                HStack(spacing: 12) {
                    Text("\(safety)")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(CountryScoreStyling.backgroundColor(for: safety))
                        )
                        .overlay(
                            Capsule()
                                .stroke(CountryScoreStyling.borderColor(for: safety), lineWidth: 1)
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        Text(CountryTravelSafeHelpers.headline(for: country))
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        Text(CountryTravelSafeHelpers.body(for: country))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                HStack(spacing: 12) {
                    Text("Normalized: \(safety)")
                    Text("Weight: 15%")
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
