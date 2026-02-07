//
//  RootTabView.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 11/15/25.
//

import SwiftUI

struct RootTabView: View {
    @EnvironmentObject private var sessionManager: SessionManager
    @EnvironmentObject private var bucketList: BucketListStore
    @EnvironmentObject private var traveled: TraveledStore

    var body: some View {
        TabView {

            // Scores / Countries
            NavigationStack {
                CountryListView()
            }
            .tabItem {
                Label("Scores", systemImage: "chart.bar.fill")
            }

            // When to Go
            NavigationStack {
                WhenToGoView()
            }
            .tabItem {
                Label("When to Go", systemImage: "calendar")
            }

            // Bucket List
            NavigationStack {
                BucketListView()
            }
            .tabItem {
                Label("Bucket List", systemImage: "bookmark.fill")
            }

            // My Travels
            NavigationStack {
                MyTravelsView()
            }
            .tabItem {
                Label("My Travels", systemImage: "backpack.fill")
            }

            // More
            NavigationStack {
                MoreView()
            }
            .tabItem {
                Label("More", systemImage: "ellipsis")
            }
        }
    }
}

// MARK: - More Tab

struct MoreView: View {
    @EnvironmentObject private var sessionManager: SessionManager

    var body: some View {
        List {

            NavigationLink("Profile") {
                ProfileView()
                    .environmentObject(sessionManager)
            }

            NavigationLink("Legal & Disclaimers") {
                LegalView()
            }

            if sessionManager.isAuthenticated {
                Button(role: .destructive) {
                    Task {
                        await sessionManager.signOut()
                    }
                } label: {
                    Text("Sign Out")
                }
            } else {
                Button {
                    // Exit guest mode → AuthGate will reveal AuthLandingView
                    sessionManager.didContinueAsGuest = false
                } label: {
                    Text("Sign in from the home screen")
                }
            }
        }
        .navigationTitle("More")
    }
}
