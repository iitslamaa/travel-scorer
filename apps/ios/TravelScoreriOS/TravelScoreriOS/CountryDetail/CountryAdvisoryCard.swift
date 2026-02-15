//
//  CountryAdvisoryCard.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 2/15/26.
//

import Foundation
import SwiftUI

struct CountryAdvisoryCard: View {
    let country: Country
    @State private var showFullAdvisory = false

    var body: some View {
        if country.advisoryLevel != nil || country.advisorySummary != nil {
            VStack(alignment: .leading, spacing: 12) {

                // Title row
                HStack {
                    Text("Travel advisory")
                        .font(.headline)
                    Spacer()
                    Text("U.S. Dept. of State · 10%")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                // Score pill + description
                HStack(spacing: 12) {
                    if let advisoryScore = country.advisoryScore {
                        Text("\(advisoryScore)")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(CountryScoreStyling.backgroundColor(for: advisoryScore))
                            )
                            .overlay(
                                Capsule()
                                    .stroke(CountryScoreStyling.borderColor(for: advisoryScore), lineWidth: 1)
                            )
                    }

                    VStack(alignment: .leading, spacing: 4) {

                        if let level = country.advisoryLevel {
                            Text(level)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }

                        if let rawSummary = country.advisorySummary,
                           !rawSummary.isEmpty {

                            let advisoryText = CountryTextHelpers.cleanAdvisory(rawSummary)

                            Text(advisoryText)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .lineLimit(showFullAdvisory ? nil : 3)
                                .fixedSize(horizontal: false, vertical: true)

                            if advisoryText.count > 200 {
                                Button {
                                    withAnimation {
                                        showFullAdvisory.toggle()
                                    }
                                } label: {
                                    Text(showFullAdvisory ? "Show less" : "Show more")
                                        .font(.footnote)
                                        .fontWeight(.semibold)
                                }
                            }
                        }
                    }
                }

                if let updated = country.advisoryUpdatedAt,
                   !updated.isEmpty {
                    Text("Last updated: \(updated)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                if let url = country.advisoryUrl {
                    Link("View official advisory", destination: url)
                        .font(.footnote)
                }

                if let advisoryScore = country.advisoryScore {
                    HStack(spacing: 12) {
                        Text("Normalized: \(advisoryScore)")
                        Text("Weight: 10%")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }
}
