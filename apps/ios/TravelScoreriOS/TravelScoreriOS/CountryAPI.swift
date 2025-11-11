//
//  CountryAPI.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 11/11/25.
//

import Foundation

enum CountryAPI {
    static let baseURL = URL(string: "https://travel-scorer.vercel.app")! // or your local URL
    static var countriesURL: URL { baseURL.appendingPathComponent("api/countries") }

    static func fetchCountries() async throws -> [Country] {
        let (data, resp) = try await URLSession.shared.data(from: countriesURL)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }

        // debug peek
        if let s = String(data: data, encoding: .utf8) { print("🌐 API sample:", s.prefix(400)) }

        // ✅ your API is a top-level array
        let dtos = try JSONDecoder().decode([CountryDTO].self, from: data)
        return dtos.map {
            Country(
                name: $0.name,
                score: deriveScore(from: $0.score, advisoryLevel: $0.advisoryLevelNumber),
                advisoryLevel: $0.advisoryLevelText
            )
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
