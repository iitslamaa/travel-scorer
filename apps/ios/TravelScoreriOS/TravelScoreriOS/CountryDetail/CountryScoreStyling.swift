//
//  CountryScoreStyling.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 2/15/26.
//

import Foundation
import SwiftUI

enum CountryScoreStyling {
    
    static func backgroundColor(for score: Int?) -> Color {
        guard let score = score else { return Color.secondary.opacity(0.1) }
        switch score {
        case 80...100: return Color.green.opacity(0.2)
        case 60..<80:  return Color.yellow.opacity(0.2)
        case 40..<60:  return Color.orange.opacity(0.2)
        default:       return Color.red.opacity(0.2)
        }
    }

    static func borderColor(for score: Int?) -> Color {
        guard let score = score else { return Color.secondary.opacity(0.4) }
        switch score {
        case 80...100: return Color.green.opacity(0.7)
        case 60..<80:  return Color.yellow.opacity(0.7)
        case 40..<60:  return Color.orange.opacity(0.7)
        default:       return Color.red.opacity(0.7)
        }
    }
}
