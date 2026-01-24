//
//  TravelScoreriOSApp.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 11/10/25.
//

import SwiftUI

@main
struct TravelScoreriOSApp: App {
    @StateObject private var bucketListStore = BucketListStore()
    @StateObject private var traveledStore = TraveledStore()

    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(bucketListStore)
                .environmentObject(traveledStore)
                // Warm cache on first launch (non-blocking)
                .task {
                    _ = await CountryAPI.refreshCountriesIfNeeded(minInterval: 0)
                }
                // Refresh when app becomes active (with cooldown inside CountryAPI)
                .onChange(of: scenePhase) { _, newPhase in
                    guard newPhase == .active else { return }
                    Task {
                        _ = await CountryAPI.refreshCountriesIfNeeded(minInterval: 60)
                    }
                }
        }
    }
}
