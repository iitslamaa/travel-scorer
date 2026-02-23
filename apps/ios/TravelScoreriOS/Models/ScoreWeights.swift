//
//  ScoreWeights.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 2/22/26.
//

import Foundation

struct ScoreWeights: Codable {
    var affordability: Double
    var visa: Double
    var advisory: Double
    var seasonality: Double
    
    static let `default` = ScoreWeights(
        affordability: 1.0,
        visa: 1.0,
        advisory: 1.0,
        seasonality: 1.0
    )
}
