//
//  WrapChips.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 12/2/25.
//

import Foundation
import SwiftUI

struct WrapChips: View {
    let countries: [SeasonalityCountry]
    let onSelect: (SeasonalityCountry) -> Void
    
    @State private var totalHeight: CGFloat = .zero
    
    var body: some View {
        self.generateContent()
            .frame(height: totalHeight)
    }
    
    private func generateContent() -> some View {
        var width: CGFloat = 0
        var height: CGFloat = 0
        
        return GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                ForEach(countries) { country in
                    chip(for: country)
                        .alignmentGuide(.leading) { d in
                            if (abs(width - d.width) > geometry.size.width) {
                                width = 0
                                height -= d.height
                            }
                            let result = width
                            width -= d.width
                            return result
                        }
                        .alignmentGuide(.top) { _ in
                            let result = height
                            if country.id == countries.last?.id {
                                width = 0
                                height = 0
                            }
                            return result
                        }
                }
            }
            .background(
                GeometryReader { geo in
                    Color.clear
                        .preference(key: HeightPreferenceKey.self, value: geo.size.height)
                }
            )
        }
        .onPreferenceChange(HeightPreferenceKey.self) {
            self.totalHeight = $0
        }
    }
    
    private func chip(for country: SeasonalityCountry) -> some View {
        let bg = scoreBackground(country.score)
        let fg = scoreTone(country.score)
        
        return Button {
            onSelect(country)
        } label: {
            HStack(spacing: 4) {
                Text((country.name ?? country.isoCode).isEmpty ? country.isoCode : (country.name ?? country.isoCode))
                    .font(.caption)
                    .fontWeight(.medium)
                if let region = country.region {
                    Text(region.uppercased())
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                if let score = country.score {
                    Text(String(Int(score.rounded())))
                        .font(.caption2.bold())
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(bg)
                        .foregroundColor(fg)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(bg)
            .foregroundColor(.primary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct HeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = .zero
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
