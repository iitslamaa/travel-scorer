//
//  CountryDTO.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 11/11/25.
//
import Foundation

struct CountryDTO: Decodable {
    let name: String
    let score: Int?                // direct score if present (0...100)
    let advisoryLevelNumber: Int?  // from advisory.level (API)

    var advisoryLevelText: String? {
        advisoryLevelNumber.map { "Level \($0)" }
    }

    private enum CodingKeys: String, CodingKey {
        case name
        case score, overallScore, rating, value
        case advisory, advisoryLevel, advisory_level
    }

    private struct Advisory: Decodable { let level: Int? }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        self.name = try c.decode(String.self, forKey: .name)

        // ✅ Correct optional chaining for various numeric score keys
        let intScore =
            (try? c.decode(Int.self,    forKey: .score))
            ?? (try? c.decode(Int.self, forKey: .overallScore))
            ?? (try? c.decode(Int.self, forKey: .rating))
            ?? (try? c.decode(Int.self, forKey: .value))

        if let s = intScore {
            self.score = s
        } else {
            // try numeric strings
            let stringScore =
                (try? c.decode(String.self, forKey: .score))
                ?? (try? c.decode(String.self, forKey: .overallScore))
                ?? (try? c.decode(String.self, forKey: .rating))
                ?? (try? c.decode(String.self, forKey: .value))

            if let s = stringScore, let v = Int(s.trimmingCharacters(in: .whitespacesAndNewlines)) {
                self.score = v
            } else {
                self.score = nil
            }
        }

        // nested advisory.level (API)
        self.advisoryLevelNumber = (try? c.decode(Advisory.self, forKey: .advisory))?.level

        // we ignore advisoryLevel/advisory_level strings here; you already show "Level N"
        _ = (try? c.decode(String.self, forKey: .advisoryLevel))
            ?? (try? c.decode(String.self, forKey: .advisory_level))
    }
}
