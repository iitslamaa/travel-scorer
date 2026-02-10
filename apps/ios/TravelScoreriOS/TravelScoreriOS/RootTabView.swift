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

            // Discovery
            NavigationStack {
                DiscoveryView()
            }
            .tabItem {
                Label("Discovery", systemImage: "globe.americas.fill")
            }

            // When To Go
            NavigationStack {
                WhenToGoView()
            }
            .tabItem {
                Label("When To Go", systemImage: "calendar")
            }

            // Lists
            NavigationStack {
                ListsView()
            }
            .tabItem {
                Label("Lists", systemImage: "list.bullet.rectangle")
            }

            // Profile
            NavigationStack {
                ProfileView()
                    .environmentObject(sessionManager)
            }
            .tabItem {
                Label("Profile", systemImage: "person.crop.circle")
            }

            // More (legal only)
            NavigationStack {
                LegalView()
            }
            .tabItem {
                Label("More", systemImage: "ellipsis")
            }
        }
    }
}

struct ListsView: View {
    var body: some View {
        List {
            NavigationLink("Bucket List") {
                BucketListView()
            }

            NavigationLink("Visited Countries") {
                MyTravelsView()
            }
        }
        .navigationTitle("Lists")
    }
}
