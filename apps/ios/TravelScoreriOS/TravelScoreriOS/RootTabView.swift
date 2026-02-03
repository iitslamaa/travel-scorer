//
//  RootTabView.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 11/15/25.
//

import Foundation
import SwiftUI
import Supabase

struct RootTabView: View {
    @EnvironmentObject private var bucketList: BucketListStore
    @EnvironmentObject private var traveled: TraveledStore

    var body: some View {
        TabView {
            // Main scores / country list
            NavigationStack {
                CountryListView()
            }
            .environmentObject(bucketList)
            .environmentObject(traveled)
            .tabItem {
                Label("Scores", systemImage: "chart.bar.fill")
            }

            // When to Go tab
            NavigationStack {
                WhenToGoView()
            }
            .tabItem {
                Label("When to Go", systemImage: "calendar")
            }

            NavigationStack {
                BucketListView()
            }
            .environmentObject(bucketList)
            .tabItem {
                Label("Bucket List", systemImage: "bookmark.fill")
            }

            NavigationStack {
                MyTravelsView()
            }
            .environmentObject(traveled)
            .tabItem {
                Label("My Travels", systemImage: "backpack.fill")
            }

            NavigationStack {
                FriendsView()
            }
            .tabItem {
                Label("Friends", systemImage: "person.2.fill")
            }

            NavigationStack {
                ProfileView()
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Sign out") {
                                Task {
                                    try? await SupabaseManager.client.auth.signOut()
                                }
                            }
                        }
                    }
            }
            .tabItem {
                Label("Profile", systemImage: "person.crop.circle")
            }
        }
    }
}

struct FriendsView: View {
    var body: some View { Text("Friends (coming soon)") }
}

struct ProfileView: View {
    var body: some View { Text("Profile (coming soon)") }
}
