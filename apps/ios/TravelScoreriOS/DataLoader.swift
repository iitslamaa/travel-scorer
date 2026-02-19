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
                    dailySpendActivitiesUsd: dto.dailySpendActivitiesUsd
                )
            }
        } catch {
            print("❌ Decode error:", error)
            return []
        }
    }

    // MARK: - Backend-controlled refresh

    struct Meta: Codable, Equatable {
        let countriesVersion: String
        let seasonalityVersion: String
    }

    private static let metaCacheKey = "cached_meta_v1"

    static func loadInitialDataIfNeeded() async {
        do {
            let remoteMeta = try await fetchRemoteMeta()
            let localMeta = loadCachedMeta()

            if localMeta != remoteMeta {
                print("🔄 Meta changed, refreshing remote data")
                await refreshRemoteData()
                saveCachedMeta(remoteMeta)
            } else {
                print("✅ Meta unchanged, using cached data")
            }
        } catch {
            print("❌ Meta check failed:", error)
        }
    }

    private static func fetchRemoteMeta() async throws -> Meta {
        let url = APIConfig.baseURL.appendingPathComponent("/api/meta")
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(Meta.self, from: data)
    }

    private static func loadCachedMeta() -> Meta? {
        guard let data = UserDefaults.standard.data(forKey: metaCacheKey) else {
            return nil
        }
        return try? JSONDecoder().decode(Meta.self, from: data)
    }

    private static func saveCachedMeta(_ meta: Meta) {
        if let data = try? JSONEncoder().encode(meta) {
            UserDefaults.standard.set(data, forKey: metaCacheKey)
        }
    }

    private static func refreshRemoteData() async {
        // Countries are globally cached and safe to refresh here
        _ = await CountryAPI.refreshCountriesIfNeeded(minInterval: 0)

        // Seasonality is view-driven and refreshes via SeasonalityViewModel
        // (on appear / month change), so we do not trigger it here.
    }
}
