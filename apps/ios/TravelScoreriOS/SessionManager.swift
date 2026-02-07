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
    @Published private(set) var userId: UUID? = nil

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
        userId = nil
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
                    userId = nil
                } else {
                    print("🧪 session is valid → isAuthenticated=true")
                    isAuthenticated = true
                    userId = session.user.id
                }
            } else {
                print("🧪 no session → isAuthenticated=false")
                isAuthenticated = false
                userId = nil
            }
        } catch {
            print("🧪 forceRefreshAuthState error:", error)
            isAuthenticated = false
            userId = nil
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
                    userId = session.user.id
                } else {
                    isAuthenticated = false
                    userId = nil
                }
            } catch {
                print("🧪 refreshFromCurrentSession error:", error)
                isAuthenticated = false
                userId = nil
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

