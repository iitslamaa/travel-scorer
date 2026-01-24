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

// MARK: - Local-first cache + refresh-on-open (with cooldown)

extension CountryAPI {

    /// Load cached countries from disk (if present).
    /// Returns nil if no cache exists or decoding fails.
    static func loadCachedCountries() -> [Country]? {
        guard let data = CountriesCache.loadData() else { return nil }
        do {
            let decoder = JSONDecoder()
            let dtos = try decoder.decode([CountryDTO].self, from: data)
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
                    dailySpendActivitiesUsd: dto.dailySpendActivitiesUsd,
                    travelSafeScore: dto.travelSafeScore
                )
            }
        } catch {
            #if DEBUG
            print("🟡 [CountriesCache] Decode failed:", error)
            #endif
            return nil
        }
    }

    /// Refreshes countries from the API unless we refreshed recently.
    /// - Parameter minInterval: Minimum seconds between refreshes (default: 60)
    /// - Returns: Fresh countries if refreshed, or nil if skipped/failed.
    static func refreshCountriesIfNeeded(minInterval: TimeInterval = 60) async -> [Country]? {
        let now = Date().timeIntervalSince1970
        let last = UserDefaults.standard.double(forKey: CountriesCache.lastRefreshKey)

        if last > 0, (now - last) < minInterval {
            #if DEBUG
            print("🟡 [CountryAPI] Skipping refresh (cooldown \(Int(minInterval))s)")
            #endif
            return nil
        }

        do {
            let data = try await fetchCountriesData()
            CountriesCache.saveData(data)
            UserDefaults.standard.set(now, forKey: CountriesCache.lastRefreshKey)

            let decoder = JSONDecoder()
            let dtos = try decoder.decode([CountryDTO].self, from: data)

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

            #if DEBUG
            print("🟢 [CountryAPI] Refreshed + cached \(countries.count) countries")
            #endif
            return countries
        } catch {
            #if DEBUG
            print("🔴 [CountryAPI] Refresh failed:", error)
            #endif
            return nil
        }
    }

    // MARK: - Private helpers

    private static func fetchCountriesData() async throws -> Data {
        let (data, resp) = try await URLSession.shared.data(from: countriesURL)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return data
    }

    private enum CountriesCache {
        static let lastRefreshKey = "countries_last_refresh_ts_v1"
        private static let fileName = "countries_cache_v1.json"

        private static var cacheURL: URL {
            let fm = FileManager.default
            let dir = (try? fm.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )) ?? fm.temporaryDirectory
            return dir.appendingPathComponent(fileName)
        }

        static func saveData(_ data: Data) {
            do {
                try data.write(to: cacheURL, options: [.atomic])
                #if DEBUG
                print("💾 [CountriesCache] Saved:", cacheURL.lastPathComponent)
                #endif
            } catch {
                #if DEBUG
                print("🔴 [CountriesCache] Save failed:", error)
                #endif
            }
        }

        static func loadData() -> Data? {
            try? Data(contentsOf: cacheURL)
        }
    }
}
