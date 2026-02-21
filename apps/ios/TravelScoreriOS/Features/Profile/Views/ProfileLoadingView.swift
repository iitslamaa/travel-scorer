//
//  ProfileLoadingView.swift
//  TravelScoreriOS
//

import SwiftUI

struct ProfileLoadingView: View {
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            ProgressView()
                .progressViewStyle(.circular)
                .scaleEffect(1.2)
        }
    }
}
