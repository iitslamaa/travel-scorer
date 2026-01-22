//
//  WhenToGoModels.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 1/22/26.
//

import Foundation

enum SeasonType: String, Codable, Hashable {
    case peak
    case shoulder
}

struct WhenToGoCountry: Identifiable, Hashable {
    /// Use slug or ISO code; must be stable
    let id: String

    let name: String
    let region: String
    let score: Int
    let seasonType: SeasonType

    /// Needed for opening full country page
    let slug: String
}
