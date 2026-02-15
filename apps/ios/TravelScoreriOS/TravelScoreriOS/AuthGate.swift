import SwiftUI

struct AuthGate: View {
    @EnvironmentObject private var sessionManager: SessionManager

    var body: some View {
        ZStack {
            // If account was just deleted, always show auth
            if sessionManager.isAuthSuppressed {
                AuthLandingView()
                    .id(sessionManager.authScreenNonce)
                    .transition(.opacity)
            } else if sessionManager.isAuthenticated || sessionManager.didContinueAsGuest {
                RootTabView()
                    .id(sessionManager.authScreenNonce)
                    .transition(.opacity)
            } else {
                AuthLandingView()
                    .id(sessionManager.authScreenNonce)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: sessionManager.isAuthenticated)
        .animation(.easeInOut(duration: 0.25), value: sessionManager.didContinueAsGuest)
        .animation(.easeInOut(duration: 0.25), value: sessionManager.authScreenNonce)
    }
}
