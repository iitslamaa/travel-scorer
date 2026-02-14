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
                                .fill(scoreBackgroundColor(for: country.score))
                        )
                        .overlay(
                            Capsule()
                                .stroke(scoreBorderColor(for: country.score), lineWidth: 1)
                        )
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .padding(.horizontal)

                // Travel advisory section — web-style factor card (always rendered with neutral fallback)
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Travel advisory")
                            .font(.headline)
                        Spacer()
                        Text("U.S. Dept. of State · 10%")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    let advisoryScore = country.advisoryScore ?? 50

                    HStack(spacing: 12) {
                        Text("\(advisoryScore)")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(scoreBackgroundColor(for: country.advisoryScore))
                            )
                            .overlay(
                                Capsule()
                                    .stroke(scoreBorderColor(for: country.advisoryScore), lineWidth: 1)
                            )

                        VStack(alignment: .leading, spacing: 4) {
                            if let level = country.advisoryLevel {
                                Text(level)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            } else {
                                Text("Advisory information is limited")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }

                            if let rawSummary = country.advisorySummary, !rawSummary.isEmpty {
                                let advisoryText = cleanAdvisory(rawSummary)

                                Text(advisoryText)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(showFullAdvisory ? nil : 3)
                                    .fixedSize(horizontal: false, vertical: true)

                                if advisoryText.count > 200 {
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
                            } else {
                                Text("Official advisory data is currently unavailable for this destination. Check official sources before travel.")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
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

                    HStack(spacing: 12) {
                        Text("Normalized: \(advisoryScore)")
                        Text("Weight: 10%")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .padding(.horizontal)
                
                // Travel safety section — web-style factor card (always rendered with neutral fallback)
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Travel safety")
                            .font(.headline)
                        Spacer()
                        Text("TravelSafe · 15%")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    let safety = country.travelSafeScore ?? 50

                    HStack(spacing: 12) {
                        Text("\(safety)")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(scoreBackgroundColor(for: country.travelSafeScore))
                            )
                            .overlay(
                                Capsule()
                                    .stroke(scoreBorderColor(for: country.travelSafeScore), lineWidth: 1)
                            )

                        VStack(alignment: .leading, spacing: 4) {
                            Text(travelSafeHeadline(for: country))
                                .font(.subheadline)
                                .fontWeight(.semibold)

                            Text(travelSafeBody(for: country))
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    if let url = country.travelSafeSourceUrl {
                        Link("View TravelSafe source", destination: url)
                            .font(.footnote)
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
                .padding(.horizontal)

                // Seasonality section — web-style factor card
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
                                        .fill(scoreBackgroundColor(for: seasonalityScore))
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(scoreBorderColor(for: seasonalityScore), lineWidth: 1)
                                )

                            VStack(alignment: .leading, spacing: 4) {
                                Text(seasonalityHeadline(for: country))
                                    .font(.subheadline)
                                    .fontWeight(.semibold)

                                Text(seasonalityBody(for: country))
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }

                        // Best months chips, if available
                        if let months = country.seasonalityBestMonths, !months.isEmpty {
                            HStack(spacing: 6) {
                                Text("Best months:")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                ForEach(months, id: \.self) { month in
                                    Text(shortMonthName(for: month))
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

                        // Footer row with weight info
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
                    .padding(.horizontal)
                }

                // Visa section — web-style factor card
                if country.visaEaseScore != nil || country.visaType != nil {
                    VStack(alignment: .leading, spacing: 12) {
                        // Title row
                        HStack {
                            Text("Visa")
                                .font(.headline)
                            Spacer()
                            Text("US passport · 5%")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }

                        // Score pill + description
                        HStack(spacing: 12) {
                            let ease = country.visaEaseScore ?? 0

                            Text(country.visaEaseScore != nil ? "\(ease)" : "—")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(scoreBackgroundColor(for: country.visaEaseScore))
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(scoreBorderColor(for: country.visaEaseScore), lineWidth: 1)
                                )

                            VStack(alignment: .leading, spacing: 4) {
                                Text(visaHeadline(for: country))
                                    .font(.subheadline)
                                    .fontWeight(.semibold)

                                Text(visaBody(for: country))
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }

                        // Details rows
                        VStack(alignment: .leading, spacing: 4) {
                            if let type = country.visaType {
                                Text("Type: \(type.replacingOccurrences(of: "_", with: " ").capitalized)")
                            }

                            if let days = country.visaAllowedDays {
                                Text("Allowed stay: up to \(days) days")
                            }

                            if let fee = country.visaFeeUsd {
                                Text(String(format: "Approx. fee: $%.0f USD", fee))
                            }
                        }
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                        if let notes = country.visaNotes, !notes.isEmpty {
                            Text(notes)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }

                        if let url = country.visaSourceUrl {
                            Link("View official visa source", destination: url)
                                .font(.footnote)
                        }

                        // Footer row with weight info
                        HStack(spacing: 12) {
                            if let ease = country.visaEaseScore {
                                Text("Normalized: \(ease)")
                            }
                            Text("Weight: 5%")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
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

    // MARK: - Factor helpers

    private func scoreBackgroundColor(for score: Int?) -> Color {
        guard let score = score else { return Color.secondary.opacity(0.1) }
        switch score {
        case 80...100: return Color.green.opacity(0.2)
        case 60..<80:  return Color.yellow.opacity(0.2)
        case 40..<60:  return Color.orange.opacity(0.2)
        default:       return Color.red.opacity(0.2)
        }
    }

    private func scoreBorderColor(for score: Int?) -> Color {
        guard let score = score else { return Color.secondary.opacity(0.4) }
        switch score {
        case 80...100: return Color.green.opacity(0.7)
        case 60..<80:  return Color.yellow.opacity(0.7)
        case 40..<60:  return Color.orange.opacity(0.7)
        default:       return Color.red.opacity(0.7)
        }
    }

    private func seasonalityHeadline(for country: Country) -> String {
        switch country.seasonalityLabel {
        case "best":
            return "Peak time to go ✅"
        case "good":
            return "Good time to go ✅"
        case "shoulder":
            return "Shoulder season"
        case "poor":
            return "Less ideal timing"
        default:
            return "Current timing"
        }
    }

    private func seasonalityBody(for country: Country) -> String {
        if let notes = country.seasonalityNotes, !notes.isEmpty {
            return notes
        }

        switch country.seasonalityLabel {
        case "best":
            return "Weather and crowd patterns are ideal right now."
        case "good":
            return "Conditions are generally favorable, with decent weather and crowds."
        case "shoulder":
            return "Decent balance of weather, crowds, and prices—expect some trade-offs."
        case "poor":
            return "This isn’t an ideal time for weather or crowds; consider different months if possible."
        default:
            return "Seasonality data is limited; timing may still be fine, but check local conditions."
        }
    }

    private func visaHeadline(for country: Country) -> String {
        guard let type = country.visaType else {
            return "Visa information is limited"
        }

        switch type {
        case "visa_free":
            return "Visa-free for US passport ✅"
        case "voa":
            return "Visa on arrival available"
        case "evisa":
            return "eVisa available online"
        case "visa_required":
            return "Visa required before travel"
        case "ban":
            return "Entry heavily restricted"
        default:
            return "Visa rules vary"
        }
    }

    private func visaBody(for country: Country) -> String {
        if let notes = country.visaNotes, !notes.isEmpty {
            return notes
        }

        guard let type = country.visaType else {
            return "Check official sources for the latest entry requirements."
        }

        switch type {
        case "visa_free":
            return "You can typically enter without arranging a visa in advance, subject to time limits."
        case "voa":
            return "Visa is issued on arrival; expect to handle paperwork and possible fees at the border."
        case "evisa":
            return "You’ll usually need to apply and pay online before travel."
        case "visa_required":
            return "You must secure a visa in advance through a consulate or official channel."
        case "ban":
            return "Current rules may severely limit or ban entry; check official guidance before planning."
        default:
            return "Entry rules may depend on your trip details; confirm with official government sources."
        }
    }
    
    private func travelSafeHeadline(for country: Country) -> String {
        guard let score = country.travelSafeScore else {
            return "Safety information is limited"
        }

        switch score {
        case 80...100:
            return "Generally very safe ✅"
        case 60..<80:
            return "Mostly safe with normal caution"
        case 40..<60:
            return "Mixed safety; stay aware"
        default:
            return "Higher risk; plan carefully"
        }
    }

    private func travelSafeBody(for country: Country) -> String {
        guard let score = country.travelSafeScore else {
            return "Based on TravelSafe global crime and safety data. Check local guidance and recent news for context."
        }

        switch score {
        case 80...100:
            return "TravelSafe suggests relatively low crime and good safety conditions, though normal precautions still apply."
        case 60..<80:
            return "Conditions are generally safe, but you should stay alert to petty crime and follow common-sense precautions."
        case 40..<60:
            return "Safety conditions vary a lot by neighborhood; research your areas and follow local advice."
        default:
            return "TravelSafe reports elevated risk. If you go, plan carefully, avoid high-risk areas, and follow official guidance."
        }
    }
    
    private func shortMonthName(for month: Int) -> String {
        // 1 = Jan, 2 = Feb, ..., 12 = Dec
        let names = ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
                     "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
        guard (1...12).contains(month) else { return "Month" }
        return names[month - 1]
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
