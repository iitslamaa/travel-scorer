//
//  ScorePill.swift
//  TravelScoreriOS
//

import SwiftUI

/// Canonical TravelAF score pill.
/// This is the single source of truth for score styling across the app.
struct ScorePill: View {
    let score: Double
    
    init(score: Int) {
        self.score = Double(score)
    }
    
    init(score: Double) {
        self.score = score
    }
    
    var body: some View {
        Text(formattedScore)
            .font(.subheadline.weight(.bold))
            .monospacedDigit()
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .foregroundStyle(backgroundColor)
            .background(
                Capsule()
                    .fill(backgroundColor.opacity(0.10))
            )
            .overlay(
                Capsule()
                    .stroke(backgroundColor.opacity(0.45), lineWidth: 1.5)
            )
            .accessibilityLabel("Score \(Int(score))")
    }
    
    private var formattedScore: String {
        String(format: "%.0f", score)
    }
    
    /// Centralized TravelAF score color system.
    /// 80–100: Green
    /// 60–79: Yellow
    /// 40–59: Orange
    /// 0–39: Red
    private var backgroundColor: Color {
        ScoreColor.background(for: Int(score))
    }
}
