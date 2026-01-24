//
//  BucketToggleButton.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 1/23/26.
//

import Foundation
import SwiftUI

struct BucketToggleButton: View {
    @EnvironmentObject private var bucketList: BucketListStore

    let countryId: String
    var size: CGFloat = 18

    var body: some View {
        Button {
            bucketList.toggle(countryId)
        } label: {
            Text("🪣")
                .font(.system(size: size))
                .opacity(bucketList.contains(countryId) ? 1.0 : 0.35)
                .accessibilityLabel(
                    bucketList.contains(countryId)
                    ? "Remove from Bucket List"
                    : "Add to Bucket List"
                )
        }
        .buttonStyle(.plain)
    }
}
