//
//  CountryDetailView.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 11/11/25.
//

import SwiftUI

struct CountryDetailView: View {
    @State var country: Country
    @State private var showFullAdvisory = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {

                // Flag + header summary (main header card)
                HStack(alignment: .center, spacing: 16) {
                    // Flag
                    Text(country.flagEmoji)
                        .font(.system(size: 60))

                    // Name + region
                    VStack(alignment: .leading, spacing: 6) {
                        Text(country.name)
                            .font(.title2)
                            .bold()

                        if let regionLabel = country.regionLabel {
                            Text(regionLabel)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    // Big score pill on the right
                    Text("\(country.score)")
                        .font(.title2.bold())
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color.green.opacity(0.2))
                        )
                        .overlay(
                            Capsule()
                                .stroke(Color.green.opacity(0.7), lineWidth: 1)
                        )
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .padding(.horizontal)

                // Travel advisory section
                if country.advisoryLevel != nil || country.advisorySummary != nil {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Travel advisory")
                            .font(.headline)

                        if let level = country.advisoryLevel {
                            Text(level)
                                .font(.subheadline)
                                .bold()
                        }

                        if let summary = country.advisorySummary, !summary.isEmpty {
                            Text(cleanAdvisory(summary))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(showFullAdvisory ? nil : 3)

                            // Only show toggle if text is long enough
                            if summary.count > 200 {
                                Button(action: {
                                    withAnimation {
                                        showFullAdvisory.toggle()
                                    }
                                }) {
                                    Text(showFullAdvisory ? "Show less" : "Show more")
                                        .font(.footnote)
                                        .fontWeight(.semibold)
                                }
                            }
                        }

                        if let updated = country.advisoryUpdatedAt, !updated.isEmpty {
                            Text("Last updated: \(updated)")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }

                        if let url = country.advisoryUrl {
                            Link("View official advisory", destination: url)
                                .font(.footnote)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .padding(.horizontal)
                }

                // Seasonality section
                if let seasonalityScore = country.seasonalityScore {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Seasonality")
                            .font(.headline)

                        HStack(spacing: 12) {
                            Text("\(seasonalityScore)")
                                .font(.system(size: 32, weight: .bold, design: .rounded))

                            VStack(alignment: .leading, spacing: 4) {
                                Text(country.seasonalityLabel?.capitalized ?? "Current timing")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)

                                if let months = country.seasonalityBestMonths, !months.isEmpty {
                                    Text("Best months: \(months.map { String($0) }.joined(separator: ", "))")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .padding(.horizontal)
                }

                // Visa section
                if country.visaEaseScore != nil || country.visaType != nil {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Visa")
                            .font(.headline)

                        if let type = country.visaType {
                            Text("Visa type: \(type.replacingOccurrences(of: "_", with: " ").capitalized)")
                                .font(.subheadline)
                        }

                        if let ease = country.visaEaseScore {
                            Text("Visa ease score: \(ease)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        if let days = country.visaAllowedDays {
                            Text("Allowed stay: up to \(days) days")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        if let fee = country.visaFeeUsd {
                            Text(String(format: "Approx. fee: $%.0f USD", fee))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        if let notes = country.visaNotes, !notes.isEmpty {
                            Text(notes)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }

                        if let url = country.visaSourceUrl {
                            Link("View official visa source", destination: url)
                                .font(.footnote)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
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

    // Clean up advisory text (fix common mojibake and HTML entities)
    private func cleanAdvisory(_ text: String) -> String {
        var s = text

        // Replace non-breaking and weird unicode spaces
        s = s.replacingOccurrences(of: "\u{00A0}", with: " ")
        s = s.replacingOccurrences(of: "\u{200B}", with: "")
        s = s.replacingOccurrences(of: "\u{FEFF}", with: "")

        // Common mojibake fixes
        s = s.replacingOccurrences(of: "â€™", with: "’")
        s = s.replacingOccurrences(of: "â€œ", with: "“")
        s = s.replacingOccurrences(of: "â€", with: "”")
        s = s.replacingOccurrences(of: "â€“", with: "–")
        s = s.replacingOccurrences(of: "â€”", with: "—")
        s = s.replacingOccurrences(of: "â€¦", with: "…")
        s = s.replacingOccurrences(of: "Â", with: "")

        // HTML entity fixes
        s = s.replacingOccurrences(of: "&amp;", with: "&")
        s = s.replacingOccurrences(of: "&quot;", with: "\"")
        s = s.replacingOccurrences(of: "&apos;", with: "'")
        s = s.replacingOccurrences(of: "&#39;", with: "'")
        s = s.replacingOccurrences(of: "&rsquo;", with: "’")
        s = s.replacingOccurrences(of: "&lsquo;", with: "‘")
        s = s.replacingOccurrences(of: "&rdquo;", with: "”")
        s = s.replacingOccurrences(of: "&ldquo;", with: "“")
        s = s.replacingOccurrences(of: "&hellip;", with: "…")
        s = s.replacingOccurrences(of: "&mdash;", with: "—")
        s = s.replacingOccurrences(of: "&ndash;", with: "–")

        // Strip leftover HTML tags (very basic)
        s = s.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)

        // Trim weird double-spaces
        while s.contains("  ") {
            s = s.replacingOccurrences(of: "  ", with: " ")
        }

        return s
    }
}

#Preview {
    NavigationStack {
        CountryDetailView(
            country: Country(
                iso2: "JP",
                name: "Japan",
                score: 90,
                region: "Asia",
                subregion: "East Asia",
                advisoryLevel: "Level 1"
            )
        )
    }
}
