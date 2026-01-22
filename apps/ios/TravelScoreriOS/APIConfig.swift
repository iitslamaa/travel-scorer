//
//  APIConfig.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 1/21/26.
//

import Foundation

enum APIConfig {
    /// Set `API_BASE_URL` in Info.plist to override (useful for debug / staging).
    /// Example: http://192.168.254.209:3000
    private static var overrideBaseURLString: String? {
        Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String
    }

    static var baseURL: URL {
        if let s = overrideBaseURLString?.trimmingCharacters(in: .whitespacesAndNewlines),
           !s.isEmpty,
           let url = URL(string: s) {
            return url
        }

        #if DEBUG
        // Local dev fallback (change if your LAN IP changes)
        return URL(string: "http://192.168.254.209:3000")!
        #else
        // Production / Preview default
        return URL(string: "https://travel-scorer.vercel.app")!
        #endif
    }
}
