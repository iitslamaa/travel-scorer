//
//  CountryDTO.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 11/11/25.
//


private let DEBUG_COUNTRY_LOGS = false
import Foundation

struct CountryDTO: Decodable {
    let iso2: String
    let name: String
    let region: String?
    let subregion: String?

    /// Final 0...100 Travelability score
    let score: Int?
    
    /// TravelSafe / crime & safety index (0...100, higher = safer)
    let travelSafeScore: Int?
    
    /// From advisory.level (1–4)
    let advisoryLevelNumber: Int?
    let advisorySummary: String?
    let advisoryUrl: URL?
    let advisoryUpdatedAt: String?

    /// Seasonality / timing
    let seasonalityScore: Int?        // 0...100 (today)
    let seasonalityLabel: String?     // "best" | "good" | "shoulder" | "poor"
    let seasonalityBestMonths: [Int]? // 1..12
    let seasonalityNotes: String?     // extra description from FM / overrides

    /// Visa (US passport)
    let visaEaseScore: Int?           // 0...100
    let visaType: String?             // visa_free | voa | evisa | visa_required | ban
    let visaAllowedDays: Int?
    let visaFeeUsd: Double?
    let visaNotes: String?
    let visaSourceUrl: URL?

    /// Affordability / daily spend (approx, hotel traveler)
    let dailySpendTotalUsd: Double?
    let dailySpendHotelUsd: Double?
    let dailySpendFoodUsd: Double?
    let dailySpendActivitiesUsd: Double?

    var advisoryLevelText: String? {
        advisoryLevelNumber.map { "Level \($0)" }
    }

    private enum CodingKeys: String, CodingKey {
        case iso2
        case name
        case region
        case subregion

        // old/easy places to look for a score
        case score, overallScore, rating, value

        // nested stuff
        case advisory
        case advisoryLevel, advisory_level
        case facts
    }

    // MARK: - Nested DTOs for decoding

    private struct Advisory: Decodable {
        let level: Int?
        let updatedAt: String?
        let url: String?
        let summary: String?
    }

    private struct DailySpend: Decodable {
        let foodUsd: Double?
        let activitiesUsd: Double?
        let hotelUsd: Double?
        let totalUsd: Double?
    }

    private struct Facts: Decodable {
        let scoreTotal: Double?                // canonical Travelability score
        
        // safety
        let travelSafeOverall: Double?

        // seasonality
        let seasonality: Double?
        let fmSeasonalityTodayScore: Double?
        let fmSeasonalityTodayLabel: String?
        let fmSeasonalityBestMonths: [Int]?
        let fmSeasonalityNotes: String?

        // visa
        let visaEase: Double?
        let visaType: String?
        let visaAllowedDays: Int?
        let visaFeeUsd: Double?
        let visaNotes: String?
        let visaSource: String?

        // affordability / daily spend
        let dailySpend: DailySpend?
    }

    private static func decodeHTML(_ text: String) -> String {
        var s = text

        // Decode numeric HTML entities (e.g. &#8217;)
        if let regex = try? NSRegularExpression(pattern: "&#([0-9]+);") {
            let matches = regex.matches(in: s, range: NSRange(s.startIndex..., in: s))
            for match in matches.reversed() {
                guard
                    match.numberOfRanges == 2,
                    let codeRange = Range(match.range(at: 1), in: s),
                    let fullRange = Range(match.range(at: 0), in: s),
                    let code = Int(s[codeRange]),
                    let scalar = UnicodeScalar(code)
                else { continue }

                s.replaceSubrange(fullRange, with: String(Character(scalar)))
            }
        }

        // Decode common named entities
        s = s
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&apos;", with: "'")
            .replacingOccurrences(of: "&rsquo;", with: "’")
            .replacingOccurrences(of: "&lsquo;", with: "‘")
            .replacingOccurrences(of: "&rdquo;", with: "”")
            .replacingOccurrences(of: "&ldquo;", with: "“")
            .replacingOccurrences(of: "&ndash;", with: "–")
            .replacingOccurrences(of: "&mdash;", with: "—")
            .replacingOccurrences(of: "&hellip;", with: "…")

        // Normalize whitespace
        s = s
            .replacingOccurrences(of: "\u{00A0}", with: " ")
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return s
    }

    // MARK: - Init

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        self.iso2 = try c.decode(String.self, forKey: .iso2)
        self.name = try c.decode(String.self, forKey: .name)
        self.region = try c.decodeIfPresent(String.self, forKey: .region)
        self.subregion = try c.decodeIfPresent(String.self, forKey: .subregion)

        // Try lots of shapes for scores: Int, Double, String
        func decodeIntLikeScore(for key: CodingKeys) -> Int? {
            // 1) Int
            if let i = try? c.decode(Int.self, forKey: key) {
                return i
            }
            // 2) Double (e.g. 83.2)
            if let d = try? c.decode(Double.self, forKey: key) {
                return Int(d.rounded())
            }
            // 3) String -> Int / Double
            if let s = try? c.decode(String.self, forKey: key) {
                let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
                if let i = Int(trimmed) {
                    return i
                }
                if let d = Double(trimmed) {
                    return Int(d.rounded())
                }
            }
            return nil
        }

        // 1️⃣ First try old/top-level numeric keys (for backwards compatibility)
        var s: Int? =
            decodeIntLikeScore(for: .score) ??
            decodeIntLikeScore(for: .overallScore) ??
            decodeIntLikeScore(for: .rating) ??
            decodeIntLikeScore(for: .value)

        // 2️⃣ Then fall back to facts.scoreTotal (your new canonical field)
        let facts = try? c.decode(Facts.self, forKey: .facts)
        if s == nil, let total = facts?.scoreTotal {
            s = Int(total.rounded())
        }
        self.score = s
        
        // TravelSafe safety score (0...100, higher = safer)
        if let ts = facts?.travelSafeOverall {
            self.travelSafeScore = Int(ts.rounded())
        } else {
            self.travelSafeScore = nil
        }

        // nested advisory.level (API)
        let advisory = try? c.decode(Advisory.self, forKey: .advisory)
        self.advisoryLevelNumber = advisory?.level
        self.advisorySummary = advisory?.summary.map { Self.decodeHTML($0) }
        self.advisoryUpdatedAt = advisory?.updatedAt
        if let urlString = advisory?.url, let url = URL(string: urlString) {
            self.advisoryUrl = url
        } else {
            self.advisoryUrl = nil
        }

        // we ignore advisoryLevel/advisory_level strings here; you already show "Level N"
        _ = (try? c.decode(String.self, forKey: .advisoryLevel))
            ?? (try? c.decode(String.self, forKey: .advisory_level))

        // --- Seasonality (from facts) ---
        if let seasonalityToday = facts?.fmSeasonalityTodayScore ?? facts?.seasonality {
            self.seasonalityScore = Int(seasonalityToday.rounded())
        } else {
            self.seasonalityScore = nil
        }
        self.seasonalityLabel = facts?.fmSeasonalityTodayLabel
        self.seasonalityBestMonths = facts?.fmSeasonalityBestMonths
        self.seasonalityNotes = facts?.fmSeasonalityNotes

        // --- Visa (from facts) ---
        if let visaEase = facts?.visaEase {
            self.visaEaseScore = Int(visaEase.rounded())
        } else {
            self.visaEaseScore = nil
        }
        self.visaType = facts?.visaType
        self.visaAllowedDays = facts?.visaAllowedDays
        self.visaFeeUsd = facts?.visaFeeUsd
        self.visaNotes = facts?.visaNotes
        if let sourceString = facts?.visaSource, let url = URL(string: sourceString) {
            self.visaSourceUrl = url
        } else {
            self.visaSourceUrl = nil
        }

        // --- Daily spend (from facts.dailySpend) ---
        if let ds = facts?.dailySpend {
            self.dailySpendTotalUsd = ds.totalUsd
            self.dailySpendHotelUsd = ds.hotelUsd
            self.dailySpendFoodUsd = ds.foodUsd
            self.dailySpendActivitiesUsd = ds.activitiesUsd
        } else {
            self.dailySpendTotalUsd = nil
            self.dailySpendHotelUsd = nil
            self.dailySpendFoodUsd = nil
            self.dailySpendActivitiesUsd = nil
        }

        // Debug (super useful right now)
        #if DEBUG
        if DEBUG_COUNTRY_LOGS {
            if let s = score {
                print("🟢 score for \(name): \(s)")
            } else {
                print("🟡 no score found for \(name)")
            }
            if let seasonalityScore {
                print("📅 seasonality for \(name): \(seasonalityScore) (\(seasonalityLabel ?? ""))")
            }
            if let visaEaseScore {
                print("🛂 visa ease for \(name): \(visaEaseScore) type=\(visaType ?? "-")")
            }
        }
        #endif
    }
}
