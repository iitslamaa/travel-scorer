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
            NavigationStack {
                CountryListView()
            }
            .tabItem {
                Label("Scores", systemImage: "chart.bar.fill")
            }

            NavigationStack {
                MyTripsView()
            }
            .tabItem {
                Label("My Trips", systemImage: "airplane.departure")
            }

            NavigationStack {
                WishlistView()
            }
            .tabItem {
                Label("Wishlist", systemImage: "heart.fill")
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

struct MyTripsView: View {
    var body: some View { Text("My Trips (coming soon)") }
}

struct WishlistView: View {
    var body: some View { Text("Wishlist (coming soon)") }
}

struct FriendsView: View {
    var body: some View { Text("Friends (coming soon)") }
}

struct ProfileView: View {
    var body: some View { Text("Profile (coming soon)") }
}
