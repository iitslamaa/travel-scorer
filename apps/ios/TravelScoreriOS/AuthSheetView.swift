//
//  AuthSheetView.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 2/5/26.
//

import SwiftUI

struct AuthSheetView: View {
    @EnvironmentObject private var sessionManager: SessionManager

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {

                Text("Sign in to save your bucket list and sync across devices.")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .padding(.top, 12)

                // Continue as Guest
                Button {
                    sessionManager.continueAsGuest()
                } label: {
                    Text("Continue as Guest")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Divider()
                    .padding(.vertical, 8)

                // Auth flow (Apple / Google / Email)
                EmailAuthView()

                Spacer(minLength: 0)
            }
            .padding()
            .navigationTitle("Sign In")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
