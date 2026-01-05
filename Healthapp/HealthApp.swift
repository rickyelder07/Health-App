//
//  HealthApp.swift
//  Netfuel
//
//  Main entry point for the Netfuel calorie tracking app
//

import SwiftUI
import Supabase

@main
struct HealthApp: App {
    @StateObject private var appState = AppState()

    init() {
        #if DEBUG
        // Configure app for UI testing if needed
        if ProcessInfo.processInfo.arguments.contains("--uitesting") {
            configureForUITesting()
        }
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .onAppear {
                    // Initialize Supabase on app launch
                    _ = SupabaseClient.shared
                }
                .onOpenURL { url in
                    handleURLCallback(url)
                }
        }
    }

    #if DEBUG
    /// Configure app state for UI testing
    private func configureForUITesting() {
        let args = ProcessInfo.processInfo.arguments
        let env = ProcessInfo.processInfo.environment

        // Force logout if requested
        if args.contains("--logout") || env["FORCE_LOGOUT"] == "true" {
            // Clear Supabase session
            Task {
                try? await SupabaseClient.shared.auth.signOut()
            }

            // Clear all local data
            if let bundleID = Bundle.main.bundleIdentifier {
                UserDefaults.standard.removePersistentDomain(forName: bundleID)
            }
            UserSettings.clear()
        }

        // Reset app state if requested
        if env["RESET_APP_STATE"] == "true" {
            TestScenarios.shared.clearAllData()
        }

        // Configure test scenarios
        TestScenarios.shared.configureFromLaunchArguments()
    }
    #endif
}

    /// Handle incoming URL callbacks (OAuth redirects)
    private func handleURLCallback(_ url: URL) {
        print("📱 App received URL: \(url.absoluteString)")

        // Check if this is a Strava OAuth callback
        // Strava redirects to netfuel://localhost?code=...&state=...
        if url.scheme == "netfuel" && url.host == "localhost" {
            print("🔵 Strava OAuth callback detected")

            // Extract authorization code from query parameters
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let queryItems = components.queryItems,
               let code = queryItems.first(where: { $0.name == "code" })?.value {
                print("✅ Extracted Strava auth code: \(code.prefix(10))...")

                // Post notification that any listening view can handle
                NotificationCenter.default.post(
                    name: .stravaOAuthCallback,
                    object: nil,
                    userInfo: ["code": code]
                )
            } else {
                print("❌ Failed to extract code from Strava callback URL")
            }
        }
        // Handle Supabase/Google OAuth callback
        else {
            Task {
                do {
                    try await SupabaseClient.shared.auth.session(from: url)
                    print("✅ Supabase OAuth callback handled successfully")
                } catch {
                    print("❌ Supabase OAuth callback error: \(error)")
                }
            }
        }
    }


// MARK: - Notification Names

extension Notification.Name {
    static let stravaOAuthCallback = Notification.Name("stravaOAuthCallback")
}

