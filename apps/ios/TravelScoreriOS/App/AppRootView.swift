//
//  AppRootView.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 2/19/26.
//

import Foundation
import SwiftUI

struct AppRootView: View {
    private let instanceId = UUID()
    @EnvironmentObject private var sessionManager: SessionManager
    
    // Controls whether intro overlay is visible
    @State private var hasFinishedIntroVideo = false
    
    init() {
        print("🚀 AppRootView INIT — instance:", instanceId)
    }
    
    var body: some View {
        let _ = print(
            "🧱 AppRootView BODY — instance:", instanceId,
            "isAuthenticated:", sessionManager.isAuthenticated,
            "didContinueAsGuest:", sessionManager.didContinueAsGuest,
            "isAuthSuppressed:", sessionManager.isAuthSuppressed,
            "userId:", sessionManager.userId as Any
        )
        
        ZStack {
            
            // MAIN APP CONTENT
            if sessionManager.isAuthSuppressed {
                AuthLandingView()
                    .onAppear {
                        print("🔐 AuthLandingView APPEARED — instance:", instanceId,
                              "userId:", sessionManager.userId as Any)
                    }
                
            } else if sessionManager.isAuthenticated || sessionManager.didContinueAsGuest {
                RootTabView()
                    .onAppear {
                        print("📲 RootTabView APPEARED — instance:", instanceId,
                              "userId:", sessionManager.userId as Any)
                    }
                
            } else {
                AuthLandingView()
                    .onAppear {
                        print("🔐 AuthLandingView APPEARED — instance:", instanceId,
                              "userId:", sessionManager.userId as Any)
                    }
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
