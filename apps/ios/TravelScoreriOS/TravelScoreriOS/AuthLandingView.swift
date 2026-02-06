import SwiftUI

struct AuthLandingView: View {
    @EnvironmentObject private var sessionManager: SessionManager

    // MARK: - State
    @State private var phase: Phase = .intro
    @State private var showAuthUI = false
    @State private var hasStarted = false

    enum Phase {
        case intro
        case loop
    }

    var body: some View {
        ZStack {
            // MARK: - Video layer (always mounted, NO animation)
            ZStack {
                VideoBackgroundView(
                    videoName: "intro",
                    videoType: "mp4",
                    loop: false
                )
                .ignoresSafeArea()
                .opacity(phase == .intro ? 1 : 0)

                VideoBackgroundView(
                    videoName: "auth_loop",
                    videoType: "mp4",
                    loop: true
                )
                .ignoresSafeArea()
                .opacity(phase == .intro ? 0 : 1)
            }

            // MARK: - Auth UI (smooth + fast)
            if !sessionManager.isAuthenticated && !sessionManager.didContinueAsGuest {
                VStack {
                    Spacer()

                    VStack(spacing: 16) {
                        EmailAuthView()

                        Button("Continue as Guest") {
                            sessionManager.continueAsGuest()
                        }
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.top, 4)
                    }
                    .frame(maxWidth: 360)
                    .opacity(showAuthUI ? 1 : 0)
                    .animation(.easeOut(duration: 0.35), value: showAuthUI)

                    Spacer()
                }
                .padding(.horizontal, 20)
            }
        }
        .onAppear {
            guard !hasStarted else { return }
            hasStarted = true

            Task { @MainActor in
                // 1️⃣ Intro plays (4s)
                try? await Task.sleep(nanoseconds: 4_000_000_000)

                // 2️⃣ Instantly switch to loop
                phase = .loop

                // 3️⃣ Show auth UI almost immediately (0.2s)
                try? await Task.sleep(nanoseconds: 200_000_000)
                showAuthUI = true
            }
        }
        .onChange(of: sessionManager.isAuthenticated) { isAuthed in
            if isAuthed {
                showAuthUI = false
            }
        }
        .onChange(of: sessionManager.didContinueAsGuest) { didGuest in
            if didGuest {
                showAuthUI = false
            }
        }
    }
}
