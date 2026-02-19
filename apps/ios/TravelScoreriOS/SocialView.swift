//
//  SocialView.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 2/9/26.
//

import Foundation
import SwiftUI

struct SocialView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("Social")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Coming soon 👀")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Social")
    }
}
