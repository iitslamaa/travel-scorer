//
//  AuthLandingView.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 2/4/26.
//

import Foundation
import SwiftUI

struct AuthLandingView: View {
    let onIntroFinished: (() -> Void)?
    @State private var showingAuthUI = false
    @State private var showLoop = false
    @State private var hasPlayedIntro = false

    var body: some View {
        ZStack {
            // Background: intro once, then loop forever
            Group {
                if showLoop {
                    VideoBackgroundView(
                        videoName: "auth_loop",
                        videoType: "mp4",
                        loop: true
                    )
                    .transition(.opacity)
                } else {
                    VideoBackgroundView(
                        videoName: "intro",
                        videoType: "mp4",
                        loop: false
                    )
                    .transition(.opacity)
                }
            }
            .ignoresSafeArea()

            // Subtle dark gradient for contrast (kept very light)
            LinearGradient(
                colors: [
                    Color.black.opacity(0.12),
                    Color.black.opacity(0.38)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Foreground: auth UI only (no text overlays)
            VStack {
                Spacer()

                if showingAuthUI {
                    EmailAuthView()
                        .transition(.opacity)
                }

                Spacer()
            }
            .padding(.horizontal, 20)
        }
        .ignoresSafeArea()
        .onAppear {
            guard !hasPlayedIntro else { return }
            hasPlayedIntro = true

            Task { @MainActor in
                // Give SwiftUI a moment to fully mount the intro video
                try? await Task.sleep(nanoseconds: 200_000_000)

                // Let intro video play fully (match Canva export length)
                try? await Task.sleep(nanoseconds: 4_000_000_000)

                // Crossfade to looping background
                withAnimation(.easeInOut(duration: 0.35)) {
                    showLoop = true
                }

                // Ensure loop is visible before notifying parent
                try? await Task.sleep(nanoseconds: 300_000_000)
                onIntroFinished?()

                // Fade in auth UI
                withAnimation(.easeInOut(duration: 0.45)) {
                    showingAuthUI = true
                }
            }
        }
    }
}
