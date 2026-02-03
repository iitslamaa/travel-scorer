import SwiftUI
import Supabase

@main
struct TravelScoreriOSApp: App {
    @State private var session: Session?
    @State private var isAuthResolved = false

    var body: some Scene {
        WindowGroup {
            AuthGate(
                session: $session,
                isAuthResolved: $isAuthResolved
            )
        }
    }
}

// MARK: - Auth Gate (isolated, lightweight)

struct AuthGate: View {
    @Binding var session: Session?
    @Binding var isAuthResolved: Bool

    @StateObject private var bucketListStore = BucketListStore()
    @StateObject private var traveledStore = TraveledStore()

    var body: some View {
        ZStack {
            if !isAuthResolved {
                ProgressView("Loading…")
                    .transition(.opacity)
            } else if session == nil {
                EmailAuthView()
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            } else {
                RootTabView()
                    .environmentObject(bucketListStore)
                    .environmentObject(traveledStore)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: isAuthResolved)
        .animation(.easeInOut(duration: 0.25), value: session != nil)
        .task {
            // Resolve session exactly once
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
