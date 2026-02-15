//
//  BucketToggleButton.swift
//  TravelScoreriOS
//

import Foundation
import SwiftUI

struct BucketToggleButton: View {

    @EnvironmentObject private var profileVM: ProfileViewModel

    let countryId: String
    var size: CGFloat = 18

    var body: some View {
        Button {
            Task {
                await profileVM.toggleBucket(countryId)
            }
        } label: {
            Text("🪣")
                .font(.system(size: size))
                .opacity(
                    profileVM.viewedBucketListCountries.contains(countryId)
                    ? 1.0
                    : 0.35
                )
                .accessibilityLabel(
                    profileVM.viewedBucketListCountries.contains(countryId)
                    ? "Remove from Bucket List"
                    : "Add to Bucket List"
                )
        }
        .buttonStyle(.plain)
    }
}
