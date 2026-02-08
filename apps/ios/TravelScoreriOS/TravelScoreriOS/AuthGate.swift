import SwiftUI

struct AuthGate: View {
    @EnvironmentObject private var sessionManager: SessionManager

    var body: some View {
        ZStack {
            if sessionManager.isAuthenticated || sessionManager.didContinueAsGuest {
                RootTabView()
                    .transition(.opacity)
            } else {
                AuthLandingView()
                    .id(sessionManager.authScreenNonce)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: sessionManager.isAuthenticated)
        .animation(.easeInOut(duration: 0.25), value: sessionManager.didContinueAsGuest)
    }
}
