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

            // Friends
            NavigationStack {
                FriendsView()
            }
            .tabItem {
                Label("Friends", systemImage: "person.2.fill")
            }

            // Profile
            NavigationStack {
                if let userId = sessionManager.userId {
                    ProfileView(userId: userId)
                } else {
                    ProgressView()
                }
            }
            .tabItem {
                Label("Profile", systemImage: "person.crop.circle")
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

struct MoreView: View {
    var body: some View {
        List {
            NavigationLink("Lists") {
                ListsView()
            }

            NavigationLink("Legal") {
                LegalView()
            }
        }
        .navigationTitle("More")
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
