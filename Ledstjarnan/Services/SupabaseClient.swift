//
//  SupabaseClient.swift
//  Ledstjarnan
//
//  Shared Supabase client (wrapper to avoid type name clash with Supabase.SupabaseClient)
//

import Foundation
import Supabase

/// Shared Supabase client wrapper (avoids name clash with SDK’s SupabaseClient in other files).
final class SupabaseManager {
    static let shared = SupabaseManager()
    
    let client: SupabaseClient
    
    private init() {
        // emitLocalSessionAsInitialSession: true — use new auth behavior (see supabase-swift #822).
        // AppState treats session as valid only when session != nil && !session.isExpired.
        self.client = SupabaseClient(
            supabaseURL: SupabaseConfig.url,
            supabaseKey: SupabaseConfig.anonKey,
            options: SupabaseClientOptions(
                auth: SupabaseClientOptions.AuthOptions(
                    emitLocalSessionAsInitialSession: true
                )
            )
        )
    }
}
