//
//  AppRootView.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 2/19/26.
//

import Foundation
import SwiftUI

struct AppRootView: View {
    @EnvironmentObject private var sessionManager: SessionManager
    
    // Controls whether intro overlay is visible
    @State private var hasFinishedIntroVideo = false
    
    var body: some View {
        ZStack {
            
            // MAIN APP CONTENT — always mounted immediately
            if sessionManager.isAuthSuppressed {
                AuthLandingView()
                    .id(sessionManager.authScreenNonce)
                
            } else if sessionManager.isAuthenticated || sessionManager.didContinueAsGuest {
                RootTabView()
                    .id(sessionManager.authScreenNonce)
                
            } else {
                AuthLandingView()
                    .id(sessionManager.authScreenNonce)
            }
            
            // INTRO VIDEO OVERLAY
            if !hasFinishedIntroVideo {
                VideoBackgroundView(
                    videoName: "intro",
                    videoType: "mp4",
                    loop: false,
                    onFinished: {
                        hasFinishedIntroVideo = true
                    }
                )
                .ignoresSafeArea()
            }
        }
    }
}
