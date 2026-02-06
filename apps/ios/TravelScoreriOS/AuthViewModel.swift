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

            // 🔑 Force session resolution (this triggers auth observers)
            _ = try await supabase.client.auth.session
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

            // 🔑 Force session resolution so SessionManager sees the login
            _ = try await supabase.client.auth.session
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

            // 🔑 Force session resolution so SessionManager sees the login
            _ = try await supabase.client.auth.session
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
