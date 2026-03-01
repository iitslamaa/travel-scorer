//
//  SessionManager.swift
//  TravelScoreriOS
//

import Foundation
import Combine
import Supabase

@MainActor
final class SessionManager: ObservableObject {

    private let instanceId = UUID()

    @Published private(set) var isAuthenticated: Bool = false {
        didSet {
            print("🔐 [SessionManager \(instanceId)] isAuthenticated DID SET")
            print("   old:", oldValue)
            print("   new:", isAuthenticated)
            print("   userId:", userId as Any)
        }
    }
    @Published var didContinueAsGuest: Bool = false
    @Published private(set) var userId: UUID? = nil {
        didSet {
            print("👤 [SessionManager \(instanceId)] userId DID SET")
            print("   old:", oldValue as Any)
            print("   new:", userId as Any)
            print("   isAuthenticated:", isAuthenticated)
        }
    }
    @Published private(set) var authScreenNonce: UUID = UUID()
    @Published private(set) var isAuthSuppressed: Bool = false


    let supabase: SupabaseManager
    private var cancellables = Set<AnyCancellable>()

    private let bucketListStore: BucketListStore
    private let traveledStore: TraveledStore
    private let listSync: ListSyncService

    private var guestBucketSnapshot: Set<String> = []
    private var guestTraveledSnapshot: Set<String> = []

    private var hasMergedGuestData = false
    private var didEnsureProfile = false

    private var syncTask: Task<Void, Never>?

    // MARK: - Initializers

    init(
        supabase: SupabaseManager,
        bucketListStore: BucketListStore,
        traveledStore: TraveledStore
    ) {
        print("🚀 SessionManager INIT — instance:", instanceId)
        self.supabase = supabase
        self.bucketListStore = bucketListStore
        self.traveledStore = traveledStore
        self.listSync = ListSyncService(supabase: supabase)

        // Start Supabase auth listener (non-blocking)
        Task {
            await supabase.startAuthListener()
        }

        guestBucketSnapshot = bucketListStore.ids
        guestTraveledSnapshot = traveledStore.ids

        // Begin observing auth state
        startAuthObservation()
    }

    // MARK: - Public API

    func continueAsGuest() {
        if isAuthSuppressed != false { isAuthSuppressed = false }
        if didContinueAsGuest != true { didContinueAsGuest = true }
        if isAuthenticated != false { isAuthenticated = false }
    }

    func signOut() async {
        try? await supabase.signOut()
        if isAuthSuppressed != false { isAuthSuppressed = false }
        if didContinueAsGuest != false { didContinueAsGuest = false }
        if isAuthenticated != false { isAuthenticated = false }
        print("🚪 signOut clearing userId")
        if userId != nil { userId = nil }
        bucketListStore.replace(with: guestBucketSnapshot)
        traveledStore.replace(with: guestTraveledSnapshot)
        hasMergedGuestData = false
        didEnsureProfile = false
        syncTask?.cancel()
        syncTask = nil
        print("🧪 signOut → isAuthenticated=false")
        bumpAuthScreen()
    }

    func bumpAuthScreen() {
        authScreenNonce = UUID()
    }

    /// Use this after a successful account deletion to force the UI back to auth,
    /// even if a stale local session token still exists briefly.
    func handleAccountDeleted() {
        if isAuthSuppressed != true { isAuthSuppressed = true }
        if didContinueAsGuest != false { didContinueAsGuest = false }
        if isAuthenticated != false { isAuthenticated = false }
        print("🚪 handleAccountDeleted clearing userId")
        if userId != nil { userId = nil }
        hasMergedGuestData = false
        didEnsureProfile = false
        syncTask?.cancel()
        syncTask = nil
        bumpAuthScreen()
    }

    /// Call this after ANY auth attempt (Apple / Google / Email)
    /// to deterministically update UI state.
    func forceRefreshAuthState(source: String = "manual") async {
        // If we just deleted an account, keep UI in logged-out state until a fresh login occurs.
        if isAuthSuppressed {
            print("🧪 forceRefreshAuthState(\(source)) suppressed → staying logged out")
            if isAuthenticated != false { isAuthenticated = false }
            if userId != nil { userId = nil }
            return
        }
        do {
            let session = try await supabase.fetchCurrentSession()

            print("🧪 forceRefreshAuthState(\(source)) session:", session as Any)

            if let session {
                // Fresh valid session observed — allow auth again
                isAuthSuppressed = false
                if session.isExpired {
                    print("🧪 session expired during refresh — staying in guest mode")
                    if isAuthenticated != false { isAuthenticated = false }
                    if userId != nil { userId = nil }
                    hasMergedGuestData = false
                } else {
                    print("🔐 forceRefreshAuthState(\(source)) setting userId:", session.user.id)
                    if isAuthenticated != true { isAuthenticated = true }
                    if userId != session.user.id { userId = session.user.id }

                    if !didEnsureProfile {
                        didEnsureProfile = true
                        let profileService = ProfileService(supabase: supabase)
                        try? await profileService.ensureProfileExists(userId: session.user.id)
                    }
                }
            } else {
                print("🧪 no session during refresh — clearing auth state")
                if isAuthenticated != false { isAuthenticated = false }
                if userId != nil { userId = nil }
                hasMergedGuestData = false
                didEnsureProfile = false
            }
        } catch {
            print("⚠️ forceRefreshAuthState transient error:", error)
            // 🔥 DO NOT clear userId or isAuthenticated on transient error
        }
    }

    // MARK: - Private

    private func mergeGuestDataIfNeeded(for userId: UUID) async {
        guard !hasMergedGuestData else { return }
        hasMergedGuestData = true

        // Merge guest bucket list into account
        for countryId in guestBucketSnapshot {
            await listSync.setBucket(
                userId: userId,
                countryId: countryId,
                add: true
            )
        }

        // Merge guest traveled list into account
        for countryId in guestTraveledSnapshot {
            await listSync.setTraveled(
                userId: userId,
                countryId: countryId,
                add: true
            )
        }

        // Clear guest snapshots after successful merge
        guestBucketSnapshot.removeAll()
        guestTraveledSnapshot.removeAll()
    }

    private func startAuthObservation() {
        refreshFromCurrentSession(source: "initial")
        listenForAuthChanges()
    }

    // MARK: - Private

    private func refreshFromCurrentSession(source: String) {
        Task {
            if self.isAuthSuppressed {
                print("🧪 refreshFromCurrentSession(\(source)) suppressed → staying logged out")
                if self.isAuthenticated != false { self.isAuthenticated = false }
                if self.userId != nil { self.userId = nil }
                return
            }
            do {
                let session = try await supabase.fetchCurrentSession()
                print("🧪 [SessionManager \(instanceId)] refreshFromCurrentSession(\(source))")
                print("   current userId BEFORE:", self.userId as Any)
                print("   session:", session as Any)

                if let session, !session.isExpired {
                    print("🔐 refreshFromCurrentSession(\(source)) VALID session for:", session.user.id)
                    if isAuthenticated != true { isAuthenticated = true }
                    if userId != session.user.id { userId = session.user.id }

                    if !didEnsureProfile {
                        didEnsureProfile = true
                        let profileService = ProfileService(supabase: supabase)
                        try? await profileService.ensureProfileExists(userId: session.user.id)
                    }
                } else {
                    print("🚪 refreshFromCurrentSession(\(source)) clearing auth state")
                    if isAuthenticated != false { isAuthenticated = false }
                    if userId != nil { userId = nil }
                    hasMergedGuestData = false
                    didEnsureProfile = false
                }
            } catch {
                print("⚠️ refreshFromCurrentSession transient error:", error)
                // 🔥 DO NOT clear userId or isAuthenticated on transient error
            }
        }
    }

    private func listenForAuthChanges() {
        supabase.authStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                print("🔁 [SessionManager \(self?.instanceId.uuidString ?? "nil")] authStatePublisher fired")
                self?.refreshFromCurrentSession(source: "authEvent")
            }
            .store(in: &cancellables)
    }

    deinit {
        print("💀 SessionManager DEINIT — instance:", instanceId)
    }
}
