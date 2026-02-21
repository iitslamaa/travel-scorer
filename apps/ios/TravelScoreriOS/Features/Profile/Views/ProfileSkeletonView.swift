//
//  ProfileSkeletonView.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 2/20/26.
//

import SwiftUI

struct ProfileSkeletonView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {

                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.gray.opacity(0.15))
                    .frame(height: 180)

                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.gray.opacity(0.15))
                    .frame(height: 120)

                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.gray.opacity(0.15))
                    .frame(height: 120)
            }
            .padding()
        }
        .redacted(reason: .placeholder)
    }
}
