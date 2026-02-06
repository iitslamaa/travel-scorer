import SwiftUI

struct AuthGate: View {
    @EnvironmentObject private var sessionManager: SessionManager

    var body: some View {
        ZStack {
            // Landing view is ALWAYS mounted so video starts instantly
            AuthLandingView()

            // Enter app if authenticated OR guest
            if sessionManager.isAuthenticated || sessionManager.didContinueAsGuest {
                RootTabView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: sessionManager.isAuthenticated)
        .animation(.easeInOut(duration: 0.25), value: sessionManager.didContinueAsGuest)
    }
}
