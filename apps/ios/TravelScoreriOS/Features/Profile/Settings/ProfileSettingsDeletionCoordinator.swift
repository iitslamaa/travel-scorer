//
//  ProfileSettingsDeletionCoordinator.swift
//  TravelScoreriOS
//

import Foundation
struct ProfileSettingsDeletionCoordinator {

    static func handleDelete(
        sessionManager: SessionManager,
        dismiss: @escaping () -> Void,
        setDeleting: @escaping (Bool) -> Void,
        setError: @escaping (String?) -> Void,
        closeSheet: @escaping () -> Void
    ) async {

        setDeleting(true)
        setError(nil)

        do {
            try await SupabaseManager.shared.deleteAccount()

            // Close delete sheet first
            closeSheet()

            // Reset app auth state
            sessionManager.handleAccountDeleted()

            // Dismiss settings view
            dismiss()

        } catch {
            setError("Failed to delete account. Please try again.")
        }

        setDeleting(false)
    }
}
