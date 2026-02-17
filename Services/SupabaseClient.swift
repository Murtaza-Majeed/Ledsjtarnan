//
//  SupabaseClient.swift
//  Ledstjarnan
//
//  Shared Supabase client instance
//

import Foundation
import Supabase

class SupabaseClient {
    static let shared = SupabaseClient()
    
    let client: SupabaseClient
    
    private init() {
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
    
    // Auth helpers
    var auth: AuthClient {
        client.auth
    }
    
    // Database helpers
    var database: PostgrestClient {
        client.database
    }
    
    // Realtime helpers
    var realtime: RealtimeClient {
        client.realtime
    }
}
