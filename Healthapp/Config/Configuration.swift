//
//  Configuration.swift
//  Netfuel
//
//  Configuration file for API keys and constants
//  Keys are loaded from Info.plist (populated from xcconfig files)
//

import Foundation

/// Application configuration and API keys
enum Configuration {

    // MARK: - Supabase Configuration
    enum Supabase {
        /// Supabase project URL
        static let url: String = {
            guard let url = Bundle.main.infoDictionary?["SUPABASE_URL"] as? String,
                  !url.isEmpty && !url.contains("YOUR_") else {
                fatalError("SUPABASE_URL not configured in Info.plist. Check Config/SETUP_INSTRUCTIONS.md")
            }
            return url
        }()

        /// Supabase anon/public key
        static let anonKey: String = {
            guard let key = Bundle.main.infoDictionary?["SUPABASE_ANON_KEY"] as? String,
                  !key.isEmpty && !key.contains("YOUR_") else {
                fatalError("SUPABASE_ANON_KEY not configured in Info.plist. Check Config/SETUP_INSTRUCTIONS.md")
            }
            return key
        }()
    }

    // MARK: - Strava API Configuration
    enum Strava {
        /// Strava OAuth Client ID
        static let clientId: String = {
            guard let id = Bundle.main.infoDictionary?["STRAVA_CLIENT_ID"] as? String,
                  !id.isEmpty && !id.contains("YOUR_") else {
                fatalError("STRAVA_CLIENT_ID not configured in Info.plist. Check Config/SETUP_INSTRUCTIONS.md")
            }
            return id
        }()

        /// Strava OAuth Client Secret
        static let clientSecret: String = {
            guard let secret = Bundle.main.infoDictionary?["STRAVA_CLIENT_SECRET"] as? String,
                  !secret.isEmpty && !secret.contains("YOUR_") else {
                fatalError("STRAVA_CLIENT_SECRET not configured in Info.plist. Check Config/SETUP_INSTRUCTIONS.md")
            }
            return secret
        }()

        /// Strava OAuth redirect URI
        /// Using custom URL scheme for mobile OAuth (works on all devices)
        /// Note: Authorization Callback Domain in Strava should be "localhost" for development
        /// The redirect_uri scheme is not strictly validated, allowing custom schemes
        static let redirectUri = "netfuel://localhost"

        /// Strava authorization URL
        static let authorizationUrl = "https://www.strava.com/oauth/authorize"

        /// Strava token exchange URL
        static let tokenUrl = "https://www.strava.com/oauth/token"

        /// Strava API base URL
        static let apiBaseUrl = "https://www.strava.com/api/v3"
    }

    // MARK: - USDA FoodData Central API Configuration
    enum USDA {
        /// USDA FoodData Central API Key
        static let apiKey: String = {
            guard let key = Bundle.main.infoDictionary?["USDA_API_KEY"] as? String,
                  !key.isEmpty && !key.contains("YOUR_") else {
                fatalError("USDA_API_KEY not configured in Info.plist. Check Config/SETUP_INSTRUCTIONS.md")
            }
            return key
        }()

        /// USDA API base URL
        static let apiBaseUrl = "https://api.nal.usda.gov/fdc/v1"
    }

    // MARK: - App Constants
    enum App {
        /// Minimum iOS version required
        static let minimumIOSVersion = "16.0"

        /// App name
        static let name = "Netfuel"

        /// App version (should match Info.plist)
        static let version = "1.0.0"

        /// App environment
        static let environment: String = {
            #if DEBUG
            return "Development"
            #else
            return "Production"
            #endif
        }()
    }

    // MARK: - Validation

    /// Validate that all required configuration values are present
    /// - Returns: True if all values are configured correctly
    static func validateConfiguration() -> Bool {
        do {
            // Access all computed properties to trigger validation
            _ = Supabase.url
            _ = Supabase.anonKey
            _ = Strava.clientId
            _ = Strava.clientSecret
            _ = USDA.apiKey

            print("✅ Configuration validated successfully")
            print("   Environment: \(App.environment)")
            print("   Supabase URL: \(Supabase.url)")
            print("   Strava Client ID: \(Strava.clientId)")

            return true
        } catch {
            print("❌ Configuration validation failed: \(error)")
            return false
        }
    }

    /// Debug helper to print configuration status (without exposing secrets)
    static func printConfigurationStatus() {
        print("🔐 Configuration Status:")
        print("   Environment: \(App.environment)")
        print("   Supabase URL: \(Supabase.url.hasPrefix("https://") ? "✅ Configured" : "❌ Invalid")")
        print("   Supabase Key: \(Supabase.anonKey.count > 10 ? "✅ Configured (\(Supabase.anonKey.count) chars)" : "❌ Missing")")
        print("   Strava Client ID: \(Strava.clientId.count > 0 ? "✅ Configured" : "❌ Missing")")
        print("   Strava Secret: \(Strava.clientSecret.count > 10 ? "✅ Configured (\(Strava.clientSecret.count) chars)" : "❌ Missing")")
        print("   USDA API Key: \(USDA.apiKey.count > 10 ? "✅ Configured (\(USDA.apiKey.count) chars)" : "❌ Missing")")
    }
}
