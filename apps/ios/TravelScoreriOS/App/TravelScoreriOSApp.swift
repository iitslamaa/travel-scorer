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
    @StateObject private var scoreWeightsStore: ScoreWeightsStore

    init() {
        print("🚀 TravelScoreriOSApp INIT")

        let bucket = BucketListStore()
        let traveled = TraveledStore()
        let weights = ScoreWeightsStore()

        let session = SessionManager(
            supabase: SupabaseManager.shared,
            bucketListStore: bucket,
            traveledStore: traveled
        )

        _bucketListStore = StateObject(wrappedValue: bucket)
        _traveledStore = StateObject(wrappedValue: traveled)
        _scoreWeightsStore = StateObject(wrappedValue: weights)
        _sessionManager = StateObject(wrappedValue: session)

        print("📦 bucketListStore instance:", ObjectIdentifier(bucket))
        print("🧳 traveledStore instance:", ObjectIdentifier(traveled))
        print("⚖️ scoreWeightsStore instance:", ObjectIdentifier(weights))
        print("🔐 sessionManager instance:", ObjectIdentifier(session))
        print("   🔎 SupabaseManager shared instance:", ObjectIdentifier(SupabaseManager.shared))
    }

    var body: some Scene {
        WindowGroup {
            let _ = print("🧱 TravelScoreriOSApp BODY — app instance:", ObjectIdentifier(self as AnyObject),
                          " sessionManager instance:", ObjectIdentifier(sessionManager),
                          " bucketListStore instance:", ObjectIdentifier(bucketListStore),
                          " traveledStore instance:", ObjectIdentifier(traveledStore),
                          " scoreWeightsStore instance:", ObjectIdentifier(scoreWeightsStore),
                          " userId:", sessionManager.userId as Any)

            AppRootView()
                .environmentObject(sessionManager)
                .environmentObject(bucketListStore)
                .environmentObject(traveledStore)
                .environmentObject(scoreWeightsStore)
        }
    }
}
