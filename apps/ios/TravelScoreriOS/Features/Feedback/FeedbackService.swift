//
//  FeedbackService.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 2/28/26.
//

import Foundation
import UIKit
import Supabase

struct FeedbackService {
    
    static func submitFeedback(
        message: String,
        userId: UUID,
        supabase: SupabaseManager
    ) async throws {
        
        let device = UIDevice.current.model
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        
        try await supabase.client
            .from("app_feedback")
            .insert([
                "user_id": userId.uuidString,
                "message": message,
                "device": device,
                "app_version": version ?? "unknown"
            ])
            .execute()
    }
}
