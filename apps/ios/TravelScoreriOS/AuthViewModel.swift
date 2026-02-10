//
//  AuthViewModel.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 2/3/26.
//

import Foundation
import Supabase
import Combine
import AuthenticationServices

@MainActor
final class AuthViewModel: ObservableObject {

    // MARK: - UI State
    @Published var email: String = ""
    @Published var otp: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // MARK: - Dependencies
    private let supabase = SupabaseManager.shared

    // MARK: - Email OTP

    func sendEmailOTP() async {
        isLoading = true
        errorMessage = nil

        do {
            try await supabase.client.auth.signInWithOTP(email: email)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func verifyEmailOTP() async {
        isLoading = true
        errorMessage = nil

        do {
            try await supabase.client.auth.verifyOTP(
                email: email,
                token: otp,
                type: .email
            )

            _ = try await supabase.client.auth.session
            try await ensureProfileExists()

        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Apple Sign In

    func signInWithApple(
        idToken: String,
        nonce: String
    ) async {
        isLoading = true
        errorMessage = nil

        do {
            let credentials = OpenIDConnectCredentials(
                provider: .apple,
                idToken: idToken,
                nonce: nonce
            )

            try await supabase.client.auth.signInWithIdToken(
                credentials: credentials
            )

            _ = try await supabase.client.auth.session
            try await ensureProfileExists()

        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Google Sign In

    func signInWithGoogle() async {
        isLoading = true
        errorMessage = nil

        do {
            try await supabase.client.auth.signInWithOAuth(
                provider: .google,
                redirectTo: URL(string: "travelscorer://login-callback")
            )

            _ = try await supabase.client.auth.session
            try await ensureProfileExists()

        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Profile Management

    private func ensureProfileExists() async throws {
        guard let user = supabase.client.auth.currentUser else { return }

        let result = try await supabase.client
            .from("profiles")
            .select("id")
            .eq("id", value: user.id.uuidString)
            .execute()

        if result.data.isEmpty {
            _ = try await supabase.client
                .from("profiles")
                .insert([
                    "id": user.id.uuidString,
                    "email": user.email ?? ""
                ])
                .execute()
        }
    }
}
