//
//  CountryAPI.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 11/11/25.
//

import Foundation

enum CountryAPI {
    static let baseURL = APIConfig.baseURL
    static var countriesURL: URL { baseURL.appendingPathComponent("api/countries") }

    static func fetchCountries() async throws -> [Country] {
        print("🔵 [CountryAPI] Fetching:", countriesURL.absoluteString)

        let (data, resp) = try await URLSession.shared.data(from: countriesURL)

        guard let http = resp as? HTTPURLResponse else {
            print("🔴 [CountryAPI] Non-HTTP response")
            throw URLError(.badServerResponse)
        }

        print("🔵 [CountryAPI] Status:", http.statusCode)

        guard (200..<300).contains(http.statusCode) else {
            if let body = String(data: data, encoding: .utf8) {
                print("🔴 [CountryAPI] Bad status \(http.statusCode). Body:", body.prefix(400))
            }
            throw URLError(.badServerResponse)
        }

        #if DEBUG
        if let s = String(data: data, encoding: .utf8) {
            print("🌐 [CountryAPI] Sample body:", s.prefix(400))
        }
        #endif

        let decoder = JSONDecoder()

        // ⬇️ KEY CHANGE: decode the array directly
        let dtos = try decoder.decode([CountryDTO].self, from: data)
        print("🟢 [CountryAPI] Decoded \(dtos.count) DTOs")

        let countries = dtos.map { dto in
            Country(
                iso2: dto.iso2,
                name: dto.name,
                score: dto.score ?? 0,
                region: dto.region,
                subregion: dto.subregion,
                advisoryLevel: dto.advisoryLevelText,
                advisorySummary: dto.advisorySummary,
                advisoryUpdatedAt: dto.advisoryUpdatedAt,
                advisoryUrl: dto.advisoryUrl,
                seasonalityScore: dto.seasonalityScore,
                seasonalityLabel: dto.seasonalityLabel,
                seasonalityBestMonths: dto.seasonalityBestMonths,
                seasonalityNotes: dto.seasonalityNotes,
                visaEaseScore: dto.visaEaseScore,
                visaType: dto.visaType,
                visaAllowedDays: dto.visaAllowedDays,
                visaFeeUsd: dto.visaFeeUsd,
                visaNotes: dto.visaNotes,
                visaSourceUrl: dto.visaSourceUrl,
                dailySpendTotalUsd: dto.dailySpendTotalUsd,
                dailySpendHotelUsd: dto.dailySpendHotelUsd,
                dailySpendFoodUsd: dto.dailySpendFoodUsd,
                dailySpendActivitiesUsd: dto.dailySpendActivitiesUsd,
                travelSafeScore: dto.travelSafeScore
            )
        }

        print("🟢 [CountryAPI] Mapped \(countries.count) countries")
        return countries
    }
}
