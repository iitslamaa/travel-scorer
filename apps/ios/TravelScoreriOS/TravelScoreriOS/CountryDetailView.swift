//
//  CountryDetailView.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 11/11/25.
//

import SwiftUI

struct CountryDetailView: View {
    @State var country: Country
    
    private let arabCountries: Set<String> = [
        "Saudi Arabia","United Arab Emirates","Qatar","Bahrain","Kuwait","Oman","Yemen",
        "Jordan","Lebanon","Syria","Iraq","Egypt","Palestine","Morocco","Algeria","Tunisia","Libya"
    ]
    
    enum ArabStatus { case arab(flag: String), nonArab }
    
    private var arabStatus: ArabStatus {
        arabCountries.contains(country.name)
        ? .arab(flag: country.flagEmoji)
        : .nonArab
    }
    
    private var arabBadge: (emoji: String, text: String, tint: Color) {
        switch arabStatus {
        case .arab (let flag):
            return(flag, "You have chosen an Arab country.", .green)
        case .nonArab:
            return("🌍", "You have chosen a non-Arab country.", .secondary)
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // your existing card
                CountryScoreCard(
                    name: country.name,
                    score: country.score,
                    advisoryLevel: country.advisoryLevel
                )

                // 4) Region badge (visual enum in action)
                HStack(alignment: .center, spacing: 12) {
                    Text(arabBadge.emoji)
                        .font(.system(size: 40))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(arabBadge.text)
                            .font(.headline)
                            .foregroundStyle(arabBadge.tint)
                        Text(country.name)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .padding(.horizontal)
            }
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .navigationTitle(country.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
