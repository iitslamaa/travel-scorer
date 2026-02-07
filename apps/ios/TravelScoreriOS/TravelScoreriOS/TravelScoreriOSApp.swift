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
    @StateObject private var sessionManager: SessionManager

    init() {
        let bucket = BucketListStore()
        let traveled = TraveledStore()
        _bucketListStore = StateObject(wrappedValue: bucket)
        _traveledStore = StateObject(wrappedValue: traveled)
        _sessionManager = StateObject(
            wrappedValue: SessionManager(
                supabase: SupabaseManager.shared,
                bucketListStore: bucket,
                traveledStore: traveled
            )
        )
    }

    var body: some Scene {
        WindowGroup {
            AuthGate()
                .environmentObject(sessionManager)
                .environmentObject(bucketListStore)
                .environmentObject(traveledStore)
        }
    }
}
