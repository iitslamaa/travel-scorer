import SwiftUI

struct AuthGate: View {
    @EnvironmentObject private var sessionManager: SessionManager

    var body: some View {
        
        // AUTH ROUTING ONLY — no intro logic here
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
    }
}
