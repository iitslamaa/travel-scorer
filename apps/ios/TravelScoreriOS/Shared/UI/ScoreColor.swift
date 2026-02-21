//
//  ScoreColor.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 2/12/26.
//

import SwiftUI

/// Centralized score → color mapping used across the app
struct ScoreColor {

    static func background(for score: Int?) -> Color {
        guard let score = score else {
            return Color.secondary.opacity(0.1)
        }

        switch score {
        case 80...100:
            return Color.green
        case 60..<80:
            return Color.yellow
        case 40..<60:
            return Color.orange
        default:
            return Color.red
        }
    }

    static func border(for score: Int?) -> Color {
        guard let score = score else {
            return Color.secondary.opacity(0.4)
        }

        switch score {
        case 80...100:
            return Color.green
        case 60..<80:
            return Color.yellow
        case 40..<60:
            return Color.orange
        default:
            return Color.red
        }
    }
}
