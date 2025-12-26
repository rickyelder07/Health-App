//
//  HealthApp.swift
//  Health App
//
//  Main entry point for the Health calorie tracking app
//

import SwiftUI

@main
struct HealthApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .onAppear {
                    // Initialize Supabase on app launch
                    _ = SupabaseClient.shared
                }
        }
    }
}

