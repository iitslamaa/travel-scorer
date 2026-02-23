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

    // Sub-scores for the little snapshot in the drawer.
    // NOTE: The backend is not consistent about key names, so ScoreSnapshot accepts multiple variants
    // (e.g. `visaEase`, `visa_ease_score`, etc.) via CodingKeys + custom decoding.
    struct ScoreSnapshot: Decodable {
        let advisory: Double?
        let seasonality: Double?
        let affordability: Double?
        let visaEase: Double?

        enum CodingKeys: String, CodingKey {
            case advisory
            case seasonality
            case affordability
            case visaEase

            // Common API variants (when backend sends *_score)
            case advisoryScore
            case seasonalityScore
            case affordabilityScore
            case visaEaseScore

            // Visa variants we may receive from different endpoints
            case visa
            case visaScore
            case visaEaseType
            case visaType
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)

            // NOTE: SeasonalityService uses `.convertFromSnakeCase`.
            // That means JSON keys like `visa_ease_score` become `visaEaseScore` here.
            self.advisory =
                try c.decodeIfPresent(Double.self, forKey: .advisory)
                ?? (try c.decodeIfPresent(Double.self, forKey: .advisoryScore))

            self.seasonality =
                try c.decodeIfPresent(Double.self, forKey: .seasonality)
                ?? (try c.decodeIfPresent(Double.self, forKey: .seasonalityScore))

            self.affordability =
                try c.decodeIfPresent(Double.self, forKey: .affordability)
                ?? (try c.decodeIfPresent(Double.self, forKey: .affordabilityScore))

            self.visaEase =
                try c.decodeIfPresent(Double.self, forKey: .visaEase)
                ?? (try c.decodeIfPresent(Double.self, forKey: .visaEaseScore))
                ?? (try c.decodeIfPresent(Double.self, forKey: .visa))
                ?? (try c.decodeIfPresent(Double.self, forKey: .visaScore))

            // Some endpoints may send a non-numeric visa descriptor like `visa_free` / `visa_required`.
            // We intentionally ignore those here because the drawer expects a 0–100 style score.
            _ = try? c.decodeIfPresent(String.self, forKey: .visaEaseType)
            _ = try? c.decodeIfPresent(String.self, forKey: .visaType)
        }
    }

    let scores: ScoreSnapshot?

    var id: String { isoCode }

    enum CodingKeys: String, CodingKey {
        // Standard fields (after convertFromSnakeCase)
        case isoCode
        case name
        case score
        case region
        case scores   // primary snapshot key

        // Alternate field names that might appear from older endpoints
        case iso
        case countryName

        // Alternate containers for the snapshot
        case scoreSnapshot
        case subScores
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        // isoCode
        let decodedIsoCode =
            try c.decodeIfPresent(String.self, forKey: .isoCode)
            ?? (try c.decodeIfPresent(String.self, forKey: .iso))

        self.isoCode = decodedIsoCode ?? ""

        // name
        self.name =
            try c.decodeIfPresent(String.self, forKey: .name)
            ?? (try c.decodeIfPresent(String.self, forKey: .countryName))

        // overall score
        self.score = try c.decodeIfPresent(Double.self, forKey: .score)

        // region
        self.region = try c.decodeIfPresent(String.self, forKey: .region)

        // score snapshot (broken into distinct steps to help compiler)
        let scoresDirect = try c.decodeIfPresent(ScoreSnapshot.self, forKey: .scores)
        let scoresAlt1 = try c.decodeIfPresent(ScoreSnapshot.self, forKey: .scoreSnapshot)
        let scoresAlt2 = try c.decodeIfPresent(ScoreSnapshot.self, forKey: .subScores)

        if let s = scoresDirect {
            self.scores = s
        } else if let s = scoresAlt1 {
            self.scores = s
        } else {
            self.scores = scoresAlt2
        }
    }
}

extension SeasonalityCountry.ScoreSnapshot {
    init(advisory: Double? = nil, seasonality: Double? = nil, affordability: Double? = nil, visaEase: Double? = nil) {
        self.advisory = advisory
        self.seasonality = seasonality
        self.affordability = affordability
        self.visaEase = visaEase
    }
}

struct SeasonalityResponse: Decodable {
    let month: Int
    let peakCountries: [SeasonalityCountry]
    let shoulderCountries: [SeasonalityCountry]
    let notes: String?

    var peak: [SeasonalityCountry] { peakCountries }
    var shoulder: [SeasonalityCountry] { shoulderCountries }
}
