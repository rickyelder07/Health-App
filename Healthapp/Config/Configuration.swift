//
//  Configuration.swift
//  Health App
//
//  Configuration file for API keys and constants
//

import Foundation

/// Application configuration and API keys
enum Configuration {
    
    // MARK: - Supabase Configuration
    enum Supabase {
        /// Supabase project URL
        static let url = "https://pomdsflvgabgblifgvsf.supabase.co"
        
        /// Supabase anon/public key
        static let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBvbWRzZmx2Z2FiZ2JsaWZndnNmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjY3MTkyNzYsImV4cCI6MjA4MjI5NTI3Nn0.4bE4yWH_uLf671TbZ9lK8-2uJlZqfQL82BCBiYEqcTM"
    }
    
    // MARK: - Strava API Configuration
    enum Strava {
        /// Strava OAuth Client ID
        static let clientId = "191889"
        
        /// Strava OAuth Client Secret
        static let clientSecret = "eca68364f240ecb75a29480656259ebdfbf13393"
        
        /// Strava OAuth redirect URI
        /// Using localhost with port 8080 where local server listens
        static let redirectUri = "http://127.0.0.1:8080"
        
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
        static let apiKey = "v0aSFFDIZajQzdKEzSagTSSr9JjfIG2xDIj1VTKl"
        
        /// USDA API base URL
        static let apiBaseUrl = "https://api.nal.usda.gov/fdc/v1"
    }
    
    // MARK: - App Constants
    enum App {
        /// Minimum iOS version required
        static let minimumIOSVersion = "16.0"
        
        /// App name
        static let name = "Health Tracker"
        
        /// App version (should match Info.plist)
        static let version = "1.0.0"
    }
    
    // MARK: - Validation
    static func validateConfiguration() -> Bool {
        let supabaseValid = !Supabase.url.contains("YOUR_") && !Supabase.anonKey.contains("YOUR_")
        let stravaValid = !Strava.clientId.contains("YOUR_") && !Strava.clientSecret.contains("YOUR_")
        let usdaValid = !USDA.apiKey.contains("YOUR_")
        
        return supabaseValid && stravaValid && usdaValid
    }
}

