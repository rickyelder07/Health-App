//
//  HealthApp.swift
//  Health App
//
//  Main entry point for the Health calorie tracking app
//

import SwiftUI
import Supabase

@main
struct HealthApp: App {
    @StateObject private var appState = AppState()
    @State private var stravaAuthCode: String?
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .onAppear {
                    // Initialize Supabase on app launch
                    _ = SupabaseClient.shared
                }
                .onOpenURL { url in
                    // Handle Google OAuth callback
                    // Strava OAuth is now handled by ASWebAuthenticationSession
                    Task {
                        do {
                            try await SupabaseClient.shared.auth.session(from: url)
                            print("✅ Google OAuth callback handled successfully")
                        } catch {
                            print("❌ Google OAuth callback error: \(error)")
                        }
                    }
                }
        }
    }
}

