//
//  AuthViewModel.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 2/3/26.
//

import Foundation
import Combine
import Supabase

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var otp: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let client = SupabaseManager.client

    func sendEmailOTP() async {
        isLoading = true
        errorMessage = nil

        do {
            try await client.auth.signInWithOTP(
                email: email
            )
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func verifyEmailOTP() async {
        isLoading = true
        errorMessage = nil

        do {
            try await client.auth.verifyOTP(
                email: email,
                token: otp,
                type: .email
            )
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
