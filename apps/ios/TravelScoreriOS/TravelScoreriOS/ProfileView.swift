//
//  ProfileView.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 2/6/26.
//

import Foundation
import SwiftUI

struct ProfileView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Profile")
                    .font(.largeTitle)
                    .bold()

                Text("Coming soon ✨")
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
            .navigationTitle("Profile")
        }
    }
}

#Preview {
    ProfileView()
}
