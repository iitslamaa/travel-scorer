//
//  APIConfig.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 1/21/26.
//

import Foundation

enum APIConfig {
    /// Set `API_BASE_URL` in Info.plist to override (useful for debug / staging).
    private static var overrideBaseURLString: String? {
        Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String
    }

    static var baseURL: URL {
        if let s = overrideBaseURLString?.trimmingCharacters(in: .whitespacesAndNewlines),
           !s.isEmpty,
           let url = URL(string: s) {
            return url
        }

        // Production default (Railway)
        return URL(string: "https://travel-app-af-production.up.railway.app")!
    }
}
