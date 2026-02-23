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
        ScrollView {
            VStack(spacing: 16) {

            // MARK: - Header Card
            VStack(spacing: 12) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Text(country.country.name)
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                                .layoutPriority(1)

                            Text(country.country.flagEmoji)
                                .font(.system(size: 26))
                                .fixedSize()
                        }

                        if let region = country.country.regionLabel {
                            Text(region.uppercased())
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                    }

                    Spacer()

                    VStack(alignment: .center, spacing: 4) {
                        ScorePill(score: country.country.score)

                        Text("Overall")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            )
            .padding(.horizontal, 20)
            .padding(.top, 16)

            // MARK: - Seasonality Insight
            if let seasonalityScore = country.country.seasonalityScore {
                VStack(alignment: .leading, spacing: 16) {

                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Seasonality")
                                .font(.headline)

                            Text("Monthly travel conditions")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text("\(seasonalityScore)")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(CountryScoreStyling.backgroundColor(for: seasonalityScore))
                            )
                            .overlay(
                                Capsule()
                                    .stroke(CountryScoreStyling.borderColor(for: seasonalityScore), lineWidth: 1)
                            )
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(CountrySeasonalityHelpers.headline(for: country.country))
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        Text(CountrySeasonalityHelpers.body(for: country.country))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    if let months = country.country.seasonalityBestMonths,
                       !months.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Best months")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 44), spacing: 8)], spacing: 8) {
                                ForEach(months, id: \.self) { month in
                                    Text(CountrySeasonalityHelpers.shortMonthName(for: month))
                                        .font(.caption2.weight(.medium))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(
                                            Capsule()
                                                .fill(Color.accentColor.opacity(0.12))
                                        )
                                }
                            }
                        }
                    }

                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color(.secondarySystemBackground))
                )
                .padding(.horizontal, 20)
            }


            }
        }
        .safeAreaInset(edge: .bottom) {
            NavigationLink {
                CountryDetailView(country: country.country)
            } label: {
                HStack(spacing: 6) {
                    Spacer()
                    Text("View Full Country Details")
                        .font(.subheadline.weight(.semibold))
                    Image(systemName: "arrow.right")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                }
                .padding(.vertical, 12)
                .foregroundStyle(.blue)
            }
            .padding(.horizontal, 20)
        }
        .scrollIndicators(.hidden)
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
