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
    @StateObject private var profileViewModel: ProfileViewModel

    init() {
        let bucket = BucketListStore()
        let traveled = TraveledStore()

        let session = SessionManager(
            supabase: SupabaseManager.shared,
            bucketListStore: bucket,
            traveledStore: traveled
        )

        _bucketListStore = StateObject(wrappedValue: bucket)
        _traveledStore = StateObject(wrappedValue: traveled)
        _sessionManager = StateObject(wrappedValue: session)

        // IMPORTANT:
        // Initialize with a placeholder UUID.
        // The real userId will be injected once auth resolves.
        _profileViewModel = StateObject(
            wrappedValue: ProfileViewModel(
                profileService: ProfileService(supabase: SupabaseManager.shared)
            )
        )
    }

    var body: some Scene {
        WindowGroup {
            AuthGate()
                .environmentObject(sessionManager)
                .environmentObject(bucketListStore)
                .environmentObject(traveledStore)
                .environmentObject(profileViewModel)
                .onReceive(sessionManager.userIdDidChange) { userId in
                    profileViewModel.setUserIdIfNeeded(userId)
                    Task {
                        await profileViewModel.load()
                    }
                }
        }
    }
}
