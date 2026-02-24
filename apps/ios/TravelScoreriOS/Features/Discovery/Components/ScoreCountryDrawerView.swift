//
//  ScoreCountryDrawerView.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 2/11/26.
//

import Foundation
import SwiftUI

struct ScoreCountryDrawerView: View {
    
    let country: Country
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            
            // Header
            HStack {
                Text(country.name)
                    .font(.title2)
                    .bold()
                
                Spacer()
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            // Main Score Pill
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("TravelAF Score")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    if let score = country.score {
                        Text("\(score)")
                            .font(.largeTitle)
                            .bold()
                            .padding(.horizontal, 18)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(ScoreColor.background(for: score))
                            )
                            .foregroundColor(.white)
                    } else {
                        Text("—")
                            .font(.largeTitle)
                            .bold()
                            .padding(.horizontal, 18)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(Color.gray.opacity(0.15))
                            )
                            .foregroundColor(.primary)
                    }
                }
                
                Spacer()
            }
            
            // Short Description
            Text(country.advisorySummary ?? "Explore detailed safety, affordability, seasonality, and visa insights for this destination.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            // Full Page Button
            NavigationLink {
                CountryDetailView(country: country)
            } label: {
                HStack {
                    Text("View Full Country Page")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Image(systemName: "arrow.right")
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(.systemGray6))
                )
            }
            .buttonStyle(.plain)
            
            Spacer(minLength: 0)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(.systemBackground))
                .shadow(radius: 12)
        )
        .padding(.horizontal)
        .padding(.bottom, 20)
    }
}
