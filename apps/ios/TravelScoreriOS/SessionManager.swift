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

    private let bucketListStore: BucketListStore
    private let traveledStore: TraveledStore
    private let listSync: ListSyncService

    // MARK: - Initializers

    init(
        supabase: SupabaseManager,
        bucketListStore: BucketListStore,
        traveledStore: TraveledStore
    ) {
        self.supabase = supabase
        self.bucketListStore = bucketListStore
        self.traveledStore = traveledStore
        self.listSync = ListSyncService(supabase: supabase)

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
        bucketListStore.clear()
        traveledStore.clear()
        print("🧪 signOut → isAuthenticated=false")
    }

    func toggleBucket(_ countryId: String) {
        // 1. Update local store first (optimistic UI)
        bucketListStore.toggle(countryId)

        // 2. If authenticated, write-through to Supabase
        guard let userId = userId else { return }

        Task {
            await listSync.setBucket(
                userId: userId,
                countryId: countryId,
                add: bucketListStore.contains(countryId)
            )
        }
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
                    bucketListStore.clear()
                    traveledStore.clear()
                } else {
                    print("🧪 session is valid → isAuthenticated=true")
                    isAuthenticated = true
                    userId = session.user.id
                    Task {
                        do {
                            let bucket = try await listSync.fetchBucketList(userId: session.user.id)
                            let traveled = try await listSync.fetchTraveled(userId: session.user.id)

                            bucketListStore.replace(with: bucket)
                            traveledStore.replace(with: traveled)
                        } catch {
                            print("🧪 list sync failed:", error)
                        }
                    }
                }
            } else {
                print("🧪 no session → isAuthenticated=false")
                isAuthenticated = false
                userId = nil
                bucketListStore.clear()
                traveledStore.clear()
            }
        } catch {
            print("🧪 forceRefreshAuthState error:", error)
            isAuthenticated = false
            userId = nil
            bucketListStore.clear()
            traveledStore.clear()
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
                    Task {
                        do {
                            let bucket = try await listSync.fetchBucketList(userId: session.user.id)
                            let traveled = try await listSync.fetchTraveled(userId: session.user.id)

                            bucketListStore.replace(with: bucket)
                            traveledStore.replace(with: traveled)
                        } catch {
                            print("🧪 list sync failed:", error)
                        }
                    }
                } else {
                    isAuthenticated = false
                    userId = nil
                    bucketListStore.clear()
                    traveledStore.clear()
                }
            } catch {
                print("🧪 refreshFromCurrentSession error:", error)
                isAuthenticated = false
                userId = nil
                bucketListStore.clear()
                traveledStore.clear()
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
