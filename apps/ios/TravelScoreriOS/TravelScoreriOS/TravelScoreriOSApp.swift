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
                // Backend-controlled refresh on app launch
                .task {
                    await DataLoader.loadInitialDataIfNeeded()
                }
                // Re-check freshness when app becomes active
                .onChange(of: scenePhase) { _, newPhase in
                    guard newPhase == .active else { return }
                    Task {
                        await DataLoader.loadInitialDataIfNeeded()
                    }
                }
        }
    }
}
