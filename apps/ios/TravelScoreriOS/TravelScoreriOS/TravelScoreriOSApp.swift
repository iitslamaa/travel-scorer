import SwiftUI
import Supabase

@main
struct TravelScoreriOSApp: App {
    @State private var session: Session?
    @State private var isAuthResolved = false
    @State private var didShowIntro = false

    var body: some Scene {
        WindowGroup {
            AuthGate(
                session: $session,
                isAuthResolved: $isAuthResolved,
                didShowIntro: $didShowIntro
            )
        }
    }
}

// MARK: - Auth Gate (isolated, lightweight)

struct AuthGate: View {
    @Binding var session: Session?
    @Binding var isAuthResolved: Bool
    @Binding var didShowIntro: Bool

    @StateObject private var bucketListStore = BucketListStore()
    @StateObject private var traveledStore = TraveledStore()

    private var isAppReviewMode: Bool {
        (Bundle.main.object(forInfoDictionaryKey: "APP_REVIEW_MODE") as? Bool) == true
    }

    var body: some View {
        ZStack {
            if !didShowIntro {
                // Always show intro first, regardless of auth state
                AuthLandingView(onIntroFinished: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        didShowIntro = true
                    }
                })
                .transition(.opacity)

            } else if !isAuthResolved {
                ProgressView("Loading…")
                    .transition(.opacity)

            } else if !isAppReviewMode && session == nil {
                AuthLandingView(onIntroFinished: nil)
                    .transition(.opacity)

            } else {
                RootTabView()
                    .environmentObject(bucketListStore)
                    .environmentObject(traveledStore)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: didShowIntro)
        .animation(.easeInOut(duration: 0.25), value: isAuthResolved)
        .animation(.easeInOut(duration: 0.25), value: isAppReviewMode || session != nil)
        .task {
            // Resolve session exactly once (in parallel with intro)
            do {
                session = try await SupabaseManager.client.auth.session
            } catch {
                session = nil
            }

            isAuthResolved = true

            // Listen for auth changes (login / logout / refresh)
            for await (_, newSession) in SupabaseManager.client.auth.authStateChanges {
                session = newSession
            }
        }
    }
}
