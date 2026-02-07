//
//  ProfileView.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 2/6/26.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var sessionManager: SessionManager
    @EnvironmentObject private var bucketList: BucketListStore
    @EnvironmentObject private var traveled: TraveledStore

    var body: some View {
        List {

            // MARK: - Header
            Section {
                VStack(spacing: 12) {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .frame(width: 72, height: 72)
                        .foregroundColor(.secondary)

                    if sessionManager.isAuthenticated {
                        Text("Signed in")
                            .font(.headline)
                    } else {
                        Text("Guest User")
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .listRowBackground(Color.clear)

            // MARK: - Stats
            Section {
                HStack(spacing: 16) {
                    StatCard(
                        title: "Traveled",
                        value: traveled.ids.count,
                        systemImage: "airplane"
                    )

                    StatCard(
                        title: "Bucket List",
                        value: bucketList.ids.count,
                        systemImage: "bookmark"
                    )
                }
                .padding(.vertical, 8)
            }
            .listRowBackground(Color.clear)

            // MARK: - Navigation
            Section {
                NavigationLink {
                    MyTravelsView()
                } label: {
                    Label("My Travels", systemImage: "backpack.fill")
                }

                NavigationLink {
                    BucketListView()
                } label: {
                    Label("Bucket List", systemImage: "bookmark.fill")
                }
            }
        }
        .navigationTitle("Profile")
    }
}
