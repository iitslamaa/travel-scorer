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
    
    @State private var pressed = true
    
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
    
    private var color: Color {
        switch score{
        case 80...:     return .green
        case 60..<80:   return .yellow
        default:        return .red
        }
    }
    var body: some View {
        Text("\(score)")
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule().fill(Color(UIColor.systemGray6)))
            .overlay(Capsule().stroke(Color(UIColor.systemGray3), lineWidth: 1))
            .foregroundStyle(color)
    }
}
