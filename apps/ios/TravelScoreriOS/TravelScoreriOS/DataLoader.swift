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

            // Fallback JSON in the bundle is a top-level array of CountryDTO
            let dtos = try JSONDecoder().decode([CountryDTO].self, from: data)
            print("✅ Decoded countries:", dtos.count)

            // SSOT: use dto.iso2 and dto.score directly
            return dtos.map { dto in
                Country(
                    iso2: dto.iso2,
                    name: dto.name,
                    score: dto.score ?? 0,
                    region: dto.region,
                    advisoryLevel: dto.advisoryLevelText
                )
            }
        } catch {
            print("❌ Decode error:", error)
            return []
        }
    }
}
