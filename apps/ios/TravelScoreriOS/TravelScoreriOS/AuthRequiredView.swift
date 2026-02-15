//
//  AuthRequiredView.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 2/15/26.
//

import Foundation
import SwiftUI

struct AuthRequiredView<Content: View>: View {
    @EnvironmentObject private var sessionManager: SessionManager
    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        if sessionManager.isAuthenticated {
            content()
        } else {
            AuthLandingView()
                .id(sessionManager.authScreenNonce)
        }
    }
}
