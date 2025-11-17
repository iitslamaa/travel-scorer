//
//  CountryScoreCard.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 11/11/25.
//

import SwiftUI

struct CountryScoreCard: View {
    let name: String
    let score: Int
    let advisoryLevel: String?
    
    @State private var pressed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(name).font(.headline)
                Spacer()
                ScorePill(score: score)
            }
            if let advisory = advisoryLevel {
                Text(advisory)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding()
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(radius: 4, y: 2)
        .padding(.horizontal)
        .padding(.top, 8)
        .scaleEffect(pressed ? 0.98 : 1) // scale based on state
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: pressed) // animate when 'pressed' changes
        .onTapGesture {
            pressed = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                pressed = false
            }
        }
    }
}

struct ScorePill: View {
    let score: Int
    
    var body: some View {
        Text("\(score)")
            .font(.headline)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(scoreBackgroundColor(for: score))
            )
            .overlay(
                Capsule()
                    .stroke(scoreBorderColor(for: score), lineWidth: 1)
            )
    }
    
    private func scoreBackgroundColor(for score: Int) -> Color {
        switch score {
        case 80...100:
            return Color.green.opacity(0.2)
        case 60..<80:
            return Color.yellow.opacity(0.2)
        case 40..<60:
            return Color.orange.opacity(0.2)
        default:
            return Color.red.opacity(0.2)
        }
    }

    private func scoreBorderColor(for score: Int) -> Color {
        switch score {
        case 80...100:
            return Color.green.opacity(0.7)
        case 60..<80:
            return Color.yellow.opacity(0.7)
        case 40..<60:
            return Color.orange.opacity(0.7)
        default:
            return Color.red.opacity(0.7)
        }
    }
}
