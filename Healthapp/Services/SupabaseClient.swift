//
//  SupabaseClient.swift
//  Health App
//
//  Singleton service for managing Supabase connection
//

import Foundation
import Supabase

/// Singleton service for managing Supabase client connection
class SupabaseService {
    
    /// Shared singleton instance
    static let shared = SupabaseService()
    
    /// Supabase client instance from the Supabase package
    let client: Supabase.SupabaseClient
    
    private init() {
        // Initialize Supabase client with configuration
        self.client = Supabase.SupabaseClient(
            supabaseURL: URL(string: Configuration.Supabase.url)!,
            supabaseKey: Configuration.Supabase.anonKey,
            options: .init(
                auth: .init(
                    // Opt-in to new session behavior - always emit locally stored session
                    emitLocalSessionAsInitialSession: true
                )
            )
        )
        
        #if DEBUG
        print("✅ Supabase client initialized")
        if !Configuration.validateConfiguration() {
            print("⚠️ WARNING: API keys not configured. Please update Configuration.swift")
        }
        #endif
    }
    
    /// Access to authentication service
    var auth: Supabase.AuthClient {
        return client.auth
    }
    
    // Note: Direct database access is deprecated in Supabase SDK
    // Use client methods directly: SupabaseClient.shared.client.from("table_name")
    // Or use: SupabaseClient.shared.client.rpc("function_name", params: [...])
    // Storage: SupabaseClient.shared.client.storage
}

// Typealias for backward compatibility with existing code
typealias SupabaseClient = SupabaseService

