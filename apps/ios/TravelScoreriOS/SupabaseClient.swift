//
//  SupabaseClient.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 2/3/26.
//

import Foundation
import Supabase

enum SupabaseManager {
    static let client: SupabaseClient = {
        guard
            let urlString = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
            let anonKey = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String,
            let url = URL(string: urlString)
        else {
            fatalError("Missing Supabase credentials in Info.plist")
        }

        return SupabaseClient(
            supabaseURL: url,
            supabaseKey: anonKey
        )
    }()
}
