//
//  CountryScoreSection.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 2/23/26.
//

import Foundation
import SwiftUI

/// Reusable score section layout used ONLY inside CountryDetailView.
/// Keeps CountryDetail consistent and future-proof.
struct CountryScoreSection: View {

    let title: String
    let weight: Int
    let score: Int
    let band: ScorePill.Band?
    let headline: String
    let subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            // Title row (legacy CountryDetail style)
            HStack {
                Text(title)
                    .font(.headline)

                Spacer()

                Text("\(weight)%")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            // Score + description row (MATCHES CountryVisaCard legacy styling)
            HStack(spacing: 12) {

                Text("\(score)")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(CountryScoreStyling.backgroundColor(for: score))
                    )
                    .overlay(
                        Capsule()
                            .stroke(CountryScoreStyling.borderColor(for: score), lineWidth: 1)
                    )

                VStack(alignment: .leading, spacing: 4) {

                    Text(headline)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    if let subtitle {
                        Text(subtitle)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Spacer()
            }

            // Footer (Normalized + Weight)
            HStack(spacing: 12) {
                Text("Normalized: \(score)")
                Text("Weight: \(weight)%")
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
