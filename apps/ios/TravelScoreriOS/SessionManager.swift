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
    @Published private(set) var authScreenNonce: UUID = UUID()

    /// Emits whenever a *real* authenticated user id becomes available
    let userIdDidChange = PassthroughSubject<UUID, Never>()

    private let supabase: SupabaseManager
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
        didContinueAsGuest = true
        isAuthenticated = false
        print("🧪 continueAsGuest → didContinueAsGuest=true")
        bumpAuthScreen()
    }

    func signOut() async {
        try? await supabase.signOut()
        didContinueAsGuest = false
        isAuthenticated = false
        userId = nil
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

    func toggleBucket(_ countryId: String) {
        // 1. Update local store first (optimistic UI)
        bucketListStore.toggle(countryId)

        if !isAuthenticated {
            guestBucketSnapshot = bucketListStore.ids
        }

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

    func toggleTraveled(_ countryId: String) {
        // 1. Update local store first (optimistic UI)
        traveledStore.toggle(countryId)

        if !isAuthenticated {
            guestTraveledSnapshot = traveledStore.ids
        }

        // 2. If authenticated, write-through to Supabase
        guard let userId = userId else { return }

        Task {
            await listSync.setTraveled(
                userId: userId,
                countryId: countryId,
                add: traveledStore.contains(countryId)
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
                    print("🧪 session expired during refresh — staying in guest mode")
                    isAuthenticated = false
                    userId = nil
                    hasMergedGuestData = false
                    bumpAuthScreen()
                } else {
                    print("🧪 session is valid → isAuthenticated=true")
                    isAuthenticated = true
                    userId = session.user.id
                    userIdDidChange.send(session.user.id)

                    if !didEnsureProfile {
                        didEnsureProfile = true
                        let profileService = ProfileService(supabase: supabase)
                        try? await profileService.ensureProfileExists(userId: session.user.id)
                    }

                    syncListsForAuthenticatedSession(session)
                }
            } else {
                print("⚠️ no session during refresh — preserving existing auth state")
                // 🔥 DO NOT clear userId or isAuthenticated here
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
            do {
                let session = try await supabase.fetchCurrentSession()
                print("🧪 refreshFromCurrentSession(\(source)):", session as Any)

                if let session, !session.isExpired {
                    isAuthenticated = true
                    userId = session.user.id
                    userIdDidChange.send(session.user.id)

                    if !didEnsureProfile {
                        didEnsureProfile = true
                        let profileService = ProfileService(supabase: supabase)
                        try? await profileService.ensureProfileExists(userId: session.user.id)
                    }

                    syncListsForAuthenticatedSession(session)
                } else {
                    print("⚠️ refresh returned no session — preserving existing auth state")
                    // 🔥 DO NOT clear userId or isAuthenticated here
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
                self?.refreshFromCurrentSession(source: "authEvent")
            }
            .store(in: &cancellables)
    }

    private func syncListsForAuthenticatedSession(_ session: Session) {
        // Cancel any in-flight sync to avoid races
        syncTask?.cancel()

        syncTask = Task { [weak self] in
            guard let self else { return }

            let uid = session.user.id
            let guestBucket = self.bucketListStore.ids
            let guestTraveled = self.traveledStore.ids

            let existingBucket = (try? await self.listSync.fetchBucketList(userId: uid)) ?? []
            let existingTraveled = (try? await self.listSync.fetchTraveled(userId: uid)) ?? []

            // 1) Merge guest data first (only once)
            if !self.hasMergedGuestData && (!guestBucket.isEmpty || !guestTraveled.isEmpty) {
                print("🧪 merging guest→account bucket=\(guestBucket.count) traveled=\(guestTraveled.count) user=\(uid)")

                let bucketToInsert = guestBucket.subtracting(existingBucket)
                let traveledToInsert = guestTraveled.subtracting(existingTraveled)

                for id in bucketToInsert {
                    await self.listSync.setBucket(userId: uid, countryId: id, add: true)
                }

                for id in traveledToInsert {
                    await self.listSync.setTraveled(userId: uid, countryId: id, add: true)
                }
            }

            // 2) Fetch from Supabase AFTER merge
            do {
                let bucket = try await self.listSync.fetchBucketList(userId: uid)
                let traveled = try await self.listSync.fetchTraveled(userId: uid)

                self.bucketListStore.replace(with: bucket)
                self.traveledStore.replace(with: traveled)

                print("🧪 hydrated from supabase bucket=\(bucket.count) traveled=\(traveled.count) user=\(uid)")

                // 3) Mark merge complete only if fetched data contains guest snapshot
                if !self.hasMergedGuestData && (!guestBucket.isEmpty || !guestTraveled.isEmpty) {
                    let mergedOK =
                        guestBucket.isSubset(of: bucket) &&
                        guestTraveled.isSubset(of: traveled)

                    if mergedOK {
                        self.hasMergedGuestData = true
                        self.guestBucketSnapshot.removeAll()
                        self.guestTraveledSnapshot.removeAll()
                        print("🧪 guest→account merge complete")
                    } else {
                        print("🧪 merge incomplete; will retry on next auth refresh")
                    }
                }
            } catch {
                print("🧪 supabase hydration failed:", error)
            }
        }
    }
}
