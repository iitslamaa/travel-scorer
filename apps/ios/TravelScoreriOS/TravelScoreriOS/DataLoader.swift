//
//  DataLoader.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 11/11/25.
//

import Foundation

enum DataLoader {
    static func loadCountriesFromBundle() -> [Country] {
        guard let url = Bundle.main.url(forResource: "countries", withExtension: "json") else {
            print("❌ countries.json NOT FOUND in bundle")
            return []
        }
        do {
            let data = try Data(contentsOf: url)
            print("✅ JSON bytes:", data.count)
            let dtos = try JSONDecoder().decode([CountryDTO].self, from: data)
            print("✅ Decoded countries:", dtos.count)
            return dtos.map {
                Country(
                    name: $0.name,
                    score: deriveScore(from: $0.score, advisoryLevel: $0.advisoryLevelNumber),
                    advisoryLevel: $0.advisoryLevelText
                )
            }
        } catch {
            print("❌ Decode error:", error)
            return []
        }
    }

    private static func deriveScore(from direct: Int?, advisoryLevel: Int?) -> Int {
        if let v = direct, (0...100).contains(v) { return v }
        switch advisoryLevel {
        case 1: return 90
        case 2: return 70
        case 3: return 50
        case 4: return 30
        case .none: return 60
        case .some(let n): return max(0, min(100, 100 - n * 20))
        }
    }
}
