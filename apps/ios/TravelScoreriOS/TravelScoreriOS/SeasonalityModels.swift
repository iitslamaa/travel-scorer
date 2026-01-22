//
//  SeasonalityModels.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 12/2/25.
//

import Foundation

struct SeasonalityCountry: Identifiable, Decodable {
    let isoCode: String
    let name: String?
    let score: Double?
    let region: String?
    let advisoryLevel: Int?
    
    // Sub-scores for the little snapshot in the drawer
    struct ScoreSnapshot: Decodable {
        let seasonality: Double?
        let affordability: Double?
        let visaEase: Double?
    }
    
    let scores: ScoreSnapshot?
    
    var id: String { isoCode }
}

struct SeasonalityResponse: Decodable {
    let month: Int
    let peakCountries: [SeasonalityCountry]
    let shoulderCountries: [SeasonalityCountry]
    let notes: String?

    var peak: [SeasonalityCountry] { peakCountries }
    var shoulder: [SeasonalityCountry] { shoulderCountries }
}
