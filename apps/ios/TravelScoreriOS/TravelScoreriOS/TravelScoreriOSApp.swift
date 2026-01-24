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
    
    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(bucketListStore)
                .environmentObject(traveledStore)
        }
    }
}
