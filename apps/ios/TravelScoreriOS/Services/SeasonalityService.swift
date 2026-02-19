//
//  SeasonalityService.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 12/2/25.
//

import Foundation

enum SeasonalityServiceError: Error {
    case invalidURL
    case badResponse
}

final class SeasonalityService {
    private let baseURL = APIConfig.baseURL

    func fetchSeasonality(forMonth month: Int) async throws -> SeasonalityResponse {
        var components = URLComponents(
            url: baseURL.appendingPathComponent("api/seasonality"),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = [
            URLQueryItem(name: "month", value: String(month))
        ]

        guard let url = components?.url else {
            throw SeasonalityServiceError.invalidURL
        }

        #if DEBUG
        print("[SeasonalityService] GET \(url.absoluteString)")
        #endif

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode) else {
            #if DEBUG
            if let http = response as? HTTPURLResponse {
                print("[SeasonalityService] ❌ Status: \(http.statusCode)")
            } else {
                print("[SeasonalityService] ❌ Non-HTTP response")
            }
            if let body = String(data: data, encoding: .utf8) {
                print("[SeasonalityService] Response body (truncated):\n\(String(body.prefix(1500)))")
            }
            #endif
            throw SeasonalityServiceError.badResponse
        }

        #if DEBUG
        print("[SeasonalityService] ✅ Status: \(http.statusCode)")
        if let body = String(data: data, encoding: .utf8) {
            print("[SeasonalityService] Response body (truncated):\n\(String(body.prefix(1500)))")
        } else {
            print("[SeasonalityService] Response body not utf8")
        }
        #endif

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        // Handle both possible backend shapes defensively
        // 1) { month, peakCountries, shoulderCountries }
        // 2) direct SeasonalityResponse
        do {
            return try decoder.decode(SeasonalityResponse.self, from: data)
        } catch {
            #if DEBUG
            print("[SeasonalityService] ❌ Decode failed:", error)
            if let body = String(data: data, encoding: .utf8) {
                print("[SeasonalityService] Raw body (truncated):\n\(String(body.prefix(1500)))")
            }
            #endif
            throw error
        }
    }
}
