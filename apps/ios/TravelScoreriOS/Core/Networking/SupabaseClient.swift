/// SupabaseClient.swift

import Foundation
import Combine
import Supabase

/// Low-level Supabase wrapper.
/// ❗️Not MainActor. Not UI. No SwiftUI state.
final class SupabaseManager {
    private let instanceId = UUID()
    static let shared = SupabaseManager()

    let client: SupabaseClient

    // Emits whenever auth state changes (sign in / sign out)
    private let authStateSubject = PassthroughSubject<Void, Never>()
    private var hasStartedAuthListener = false
    var authStatePublisher: AnyPublisher<Void, Never> {
        authStateSubject.eraseToAnyPublisher()
    }

    private init() {
        guard
            let urlString = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
            let anonKey = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String,
            let url = URL(string: urlString)
        else {
            fatalError("Missing Supabase credentials in Info.plist")
        }

        self.client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: anonKey,
            options: SupabaseClientOptions(
                auth: .init(
                    emitLocalSessionAsInitialSession: true
                )
            )
        )
        print("🛰 SupabaseManager INIT — instance:", instanceId)
        print("   URL:", url)
    }

    func startAuthListener() async {
        print("🎧 [\(instanceId)] startAuthListener called. hasStartedAuthListener:", hasStartedAuthListener)
        guard !hasStartedAuthListener else { return }
        hasStartedAuthListener = true

        await client.auth.onAuthStateChange { [weak self] _, _ in
            Task { @MainActor in
                print("🔁 [\(self?.instanceId.uuidString ?? "nil")] Supabase auth state changed")
                self?.authStateSubject.send(())
            }
        }
    }

    // MARK: - Session

    /// Supabase SDK exposes session asynchronously
    func fetchCurrentSession() async throws -> Session? {
        let session = try await client.auth.session
        print("📡 [\(instanceId)] fetchCurrentSession →", session as Any)
        return session
    }

    // MARK: - Auth helpers

    func signOut() async throws {
        print("🚪 [\(instanceId)] Supabase signOut called")
        try await client.auth.signOut()
    }

    /// Deletes the currently authenticated user account via Edge Function
    func deleteAccount() async throws {
        print("🗑 [\(instanceId)] deleteAccount invoked")
        // Call the deployed edge function
        _ = try await client.functions.invoke("delete-account")

        // Sign out locally after backend deletion
        try await client.auth.signOut()
    }

    // MARK: - User Queries

    /// Returns the currently authenticated user's ID
    var currentUserId: UUID? {
        let id = client.auth.currentUser?.id
        print("🧾 [\(instanceId)] currentUserId read →", id as Any)
        return id
    }

    /// Search users by username (case-insensitive, partial match)
    func searchUsers(byUsername query: String) async throws -> [Profile] {
        print("🔎 [\(instanceId)] searchUsers called with query:", query)
        let response: PostgrestResponse<[Profile]> = try await client
            .from("profiles")
            .select("*")
            .ilike("username", pattern: "%\(query)%")
            .limit(20)
            .execute()
        print("🔎 [\(instanceId)] searchUsers result count:", response.value.count)
        return response.value
    }
    deinit {
        print("💀 SupabaseManager DEINIT — instance:", instanceId)
    }
}
