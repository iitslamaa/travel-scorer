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
    @EnvironmentObject private var profileVM: ProfileViewModel

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

            // Friends (auth required)
            NavigationStack {
                if sessionManager.isAuthenticated,
                   let userId = sessionManager.userId {
                    FriendsView(userId: userId)
                } else {
                    VStack(spacing: 20) {
                        Spacer()

                        Text("Create an account to add your friends!")
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Button {
                            sessionManager.didContinueAsGuest = false
                            sessionManager.bumpAuthScreen()
                        } label: {
                            Text("Create Account / Log In")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal, 40)

                        Spacer()
                    }
                }
            }
            .tabItem {
                Label("Friends", systemImage: "person.2.fill")
            }
            .badge(profileVM.pendingRequestCount)

            // Profile (auth required)
            NavigationStack {
                if sessionManager.isAuthenticated,
                   let userId = sessionManager.userId {
                    ProfileView(userId: userId)
                } else {
                    VStack(spacing: 20) {
                        Spacer()

                        Text("Create an account to customize your profile!")
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Button {
                            sessionManager.didContinueAsGuest = false
                            sessionManager.bumpAuthScreen()
                        } label: {
                            Text("Create Account / Log In")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal, 40)

                        Spacer()
                    }
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
