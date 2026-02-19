//
//  FullBucketListView.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 2/11/26.
//

import SwiftUI

struct FullBucketListView: View {
    @EnvironmentObject private var profileVM: ProfileViewModel

    let userId: UUID

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {

                CollapsibleCountrySection(
                    title: "Want to Visit",
                    countryCodes: flags(for: profileVM.viewedBucketListCountries),
                    highlightColor: .blue
                )
            }
            .padding()
        }
        .navigationTitle("Full Bucket List")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            profileVM.setUserIdIfNeeded(userId)
        }
    }

    private func flags(for ids: Set<String>) -> [String] {
        ids.map { $0.uppercased() }.sorted()
    }
}
