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

            // MARK: - User
            Section {
                if sessionManager.isAuthenticated {
                    Text("Signed in")
                        .font(.headline)
                } else {
                    Text("Guest User")
                        .foregroundColor(.secondary)
                }
            }

            // MARK: - Stats
            Section("Stats") {
                Label {
                    Text("\(traveled.ids.count) countries traveled")
                } icon: {
                    Image(systemName: "airplane")
                }

                Label {
                    Text("\(bucketList.ids.count) on bucket list")
                } icon: {
                    Image(systemName: "bookmark")
                }
            }
        }
        .navigationTitle("Profile")
    }
}
