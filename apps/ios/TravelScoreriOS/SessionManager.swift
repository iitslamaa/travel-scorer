//
//  SessionManager.swift
//  TravelScoreriOS
//

import Foundation
import Combine
import Supabase

@MainActor
final class SessionManager: ObservableObject {

    @Published private(set) var isAuthenticated: Bool = false
    @Published var didContinueAsGuest: Bool = false

    private let supabase: SupabaseManager
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initializers

    init(supabase: SupabaseManager) {
        self.supabase = supabase

        // Start Supabase auth listener (non-blocking)
        Task {
            await supabase.startAuthListener()
        }

        // Begin observing auth state
        startAuthObservation()
    }

    // MARK: - Public API

    func continueAsGuest() {
        didContinueAsGuest = true
        isAuthenticated = false
        print("🧪 continueAsGuest → didContinueAsGuest=true")
    }

    func signOut() async {
        try? await supabase.signOut()
        didContinueAsGuest = false
        isAuthenticated = false
        print("🧪 signOut → isAuthenticated=false")
    }

    /// Call this after ANY auth attempt (Apple / Google / Email)
    /// to deterministically update UI state.
    func forceRefreshAuthState(source: String = "manual") async {
        do {
            let session = try await supabase.fetchCurrentSession()

            print("🧪 forceRefreshAuthState(\(source)) session:", session as Any)

            if let session {
                if session.isExpired {
                    print("🧪 session is expired → treating as logged out")
                    isAuthenticated = false
                } else {
                    print("🧪 session is valid → isAuthenticated=true")
                    isAuthenticated = true
                }
            } else {
                print("🧪 no session → isAuthenticated=false")
                isAuthenticated = false
            }
        } catch {
            print("🧪 forceRefreshAuthState error:", error)
            isAuthenticated = false
        }
    }

    // MARK: - Auth observation

    private func startAuthObservation() {
        refreshFromCurrentSession(source: "initial")
        listenForAuthChanges()
    }

    // MARK: - Private

    private func refreshFromCurrentSession(source: String) {
        Task {
            do {
                let session = try await supabase.fetchCurrentSession()
                print("🧪 refreshFromCurrentSession(\(source)):", session as Any)

                if let session, !session.isExpired {
                    isAuthenticated = true
                } else {
                    isAuthenticated = false
                }
            } catch {
                print("🧪 refreshFromCurrentSession error:", error)
                isAuthenticated = false
            }
        }
    }

    private func listenForAuthChanges() {
        supabase.authStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refreshFromCurrentSession(source: "authEvent")
            }
            .store(in: &cancellables)
    }
}
