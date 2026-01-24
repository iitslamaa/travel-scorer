//
//  RootTabView.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 11/15/25.
//

import Foundation
import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            // Main scores / country list
            NavigationStack {
                CountryListView()
            }
            .tabItem {
                Label("Scores", systemImage: "chart.bar.fill")
            }

            // NEW: When to Go tab
            NavigationStack {
                WhenToGoView()
            }
            .tabItem {
                Label("When to Go", systemImage: "calendar")
            }

            NavigationStack {
                BucketListView()
            }
            .tabItem {
                Label("Bucket List", systemImage: "bookmark.fill")
            }

            NavigationStack {
                MyTravelsView()
            }
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
