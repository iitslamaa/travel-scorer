//
//  LaunchView.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 2/4/26.
//

import Foundation
import SwiftUI
import Supabase

struct LaunchView: View {
    let session: Session?

    @State private var introFinished = false

    var body: some View {
        ZStack {
            if !introFinished {
                // Intro always plays
                VideoBackgroundView(
                    videoName: "intro",
                    videoType: "mp4",
                    loop: false
                )
                .ignoresSafeArea()
            } else {
                // After intro finishes
                if session == nil {
                    AuthLandingView(onIntroFinished: nil)
                } else {
                    RootTabView()
                }
            }
        }
        .onAppear {
            Task { @MainActor in
                // Match intro duration exactly (4s)
                try? await Task.sleep(nanoseconds: 4_000_000_000)
                withAnimation(.easeOut(duration: 0.4)) {
                    introFinished = true
                }
            }
        }
    }
}
