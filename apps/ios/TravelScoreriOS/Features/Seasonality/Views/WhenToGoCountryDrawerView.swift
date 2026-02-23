//
//  WhenToGoCountryDrawerView.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 2/20/26.
//

import SwiftUI

struct WhenToGoCountryDrawerView: View {
    @EnvironmentObject private var weightsStore: ScoreWeightsStore

    let country: WhenToGoItem

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            header

            VStack(spacing: 16) {
                scoreRow(
                    title: "Advisory",
                    value: Double(country.country.advisoryScore ?? 0),
                    weightPercentage: weightsStore.advisoryPercentage
                )
                scoreRow(
                    title: "Visa ease",
                    value: Double(country.country.visaEaseScore ?? 0),
                    weightPercentage: weightsStore.visaPercentage
                )
                scoreRow(
                    title: "Seasonality",
                    value: Double(country.seasonalityScore),
                    weightPercentage: 0
                )
            }
            .padding(14)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 18))

            NavigationLink {
                CountryDetailView(country: country.country)
            } label: {
                HStack(spacing: 6) {
                    Text("View Full Country Details")
                        .font(.subheadline.weight(.semibold))
                    Image(systemName: "arrow.right")
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundStyle(.blue)
            }
            .padding(.top, 4)

            Spacer(minLength: 0)
        }
        .padding(16)
        .navigationBarHidden(true)
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(country.country.name)
                        .font(.system(size: 28, weight: .bold))
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)

                    Text(country.country.flagEmoji)
                        .font(.system(size: 34))
                }

                if let region = country.country.regionLabel {
                    Text(region.uppercased())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Text("OVERALL")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)

                ScorePill(score: country.country.score)
                    .scaleEffect(1.35)
            }
            .padding(.trailing, 18)
        }
    }

    private func scoreRow(title: String, value: Double, weightPercentage: Int) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))

                Text("Weight: \(weightPercentage)%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            ScorePill(score: value)
        }
        .padding(.vertical, 6)
    }
}
