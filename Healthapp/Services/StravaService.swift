//
//  StravaService.swift
//  Netfuel
//
//  Service for Strava OAuth and activity syncing
//

import Foundation
import Supabase
import UIKit

/// Service for managing Strava OAuth and API interactions
class StravaService {
    private let supabase = SupabaseClient.shared

    // MARK: - OAuth Flow

    /// Start OAuth authorization flow using custom URL scheme
    /// - Parameter userId: Current user's ID for state parameter
    /// - Note: After user authorizes, Strava will redirect to netfuel://localhost?code=...
    ///         The app handles this via .onOpenURL in the main app/view
    func startOAuthFlow(userId: UUID) {
        let authUrl = buildAuthorizationURL(userId: userId)

        print("🔵 Starting OAuth flow with custom URL scheme")
        print("   Full URL: \(authUrl)")
        print("   Redirect URI: \(Configuration.Strava.redirectUri)")
        print("   After authorization, Strava will redirect to: \(Configuration.Strava.redirectUri)")

        guard let url = URL(string: authUrl) else {
            print("❌ Failed to create URL")
            return
        }

        // Open authorization URL in Safari
        // After user approves, iOS will automatically return to the app via the custom URL scheme
        UIApplication.shared.open(url) { success in
            if success {
                print("✅ Opened Strava authorization page in Safari")
                print("💡 Waiting for user to authorize...")
            } else {
                print("❌ Failed to open Safari")
            }
        }
    }
    
    /// Build the Strava authorization URL
    private func buildAuthorizationURL(userId: UUID) -> String {
        let scope = "activity:read_all,profile:read_all"
        let state = userId.uuidString

        // URL encode the redirect URI - allow : and / for custom URL schemes
        // Custom URL schemes like "netfuel://localhost" need : and / preserved
        guard let encodedRedirectUri = Configuration.Strava.redirectUri.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            print("❌ Failed to encode redirect URI")
            return ""
        }

        print("📝 Original redirect URI: \(Configuration.Strava.redirectUri)")
        print("📝 Encoded redirect URI: \(encodedRedirectUri)")

        let authUrl = "\(Configuration.Strava.authorizationUrl)?" +
               "client_id=\(Configuration.Strava.clientId)&" +
               "redirect_uri=\(encodedRedirectUri)&" +
               "response_type=code&" +
               "approval_prompt=auto&" +
               "scope=\(scope)&" +
               "state=\(state)"

        print("🔗 Full authorization URL: \(authUrl)")
        return authUrl
    }
    
    /// Exchange authorization code for access token
    /// - Parameters:
    ///   - code: Authorization code from Strava
    ///   - userId: User ID to store connection for
    /// - Returns: Strava connection
    /// - Throws: Error if exchange fails
    func exchangeToken(code: String, userId: UUID) async throws -> StravaConnection {
        let tokenUrl = URL(string: Configuration.Strava.tokenUrl)!
        
        var request = URLRequest(url: tokenUrl)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "client_id": Configuration.Strava.clientId,
            "client_secret": Configuration.Strava.clientSecret,
            "code": code,
            "grant_type": "authorization_code"
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw StravaError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            print("❌ Strava token exchange failed with status: \(httpResponse.statusCode)")
            if let jsonString = String(data: data, encoding: .utf8) {
                print("❌ Response: \(jsonString)")
            }
            throw StravaError.tokenExchangeFailed(httpResponse.statusCode)
        }
        
        let tokenResponse = try JSONDecoder().decode(StravaTokenResponse.self, from: data)
        print("✅ Strava token exchange successful")
        
        // Store connection in Supabase
        return try await storeConnection(tokenResponse: tokenResponse, userId: userId)
    }
    
    /// Refresh expired access token
    /// - Parameter connection: Existing Strava connection
    /// - Returns: Updated connection with new tokens
    /// - Throws: Error if refresh fails
    func refreshToken(connection: StravaConnection) async throws -> StravaConnection {
        let tokenUrl = URL(string: Configuration.Strava.tokenUrl)!
        
        var request = URLRequest(url: tokenUrl)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "client_id": Configuration.Strava.clientId,
            "client_secret": Configuration.Strava.clientSecret,
            "refresh_token": connection.refreshToken,
            "grant_type": "refresh_token"
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw StravaError.tokenRefreshFailed
        }
        
        let tokenResponse = try JSONDecoder().decode(StravaRefreshResponse.self, from: data)
        print("✅ Strava token refreshed")
        
        // Update connection in Supabase
        return try await updateConnection(userId: connection.userId, tokenResponse: tokenResponse)
    }
    
    // MARK: - Connection Management
    
    /// Store Strava connection in Supabase
    private func storeConnection(tokenResponse: StravaTokenResponse, userId: UUID) async throws -> StravaConnection {
        let expiresAt = Date(timeIntervalSince1970: TimeInterval(tokenResponse.expiresAt))
        
        let connectionRequest = StravaConnectionRequest(
            userId: userId.uuidString,
            accessToken: tokenResponse.accessToken,
            refreshToken: tokenResponse.refreshToken,
            expiresAt: ISO8601DateFormatter().string(from: expiresAt),
            athleteId: String(tokenResponse.athlete.id),
            athleteUsername: tokenResponse.athlete.username ?? "",
            athleteFirstname: tokenResponse.athlete.firstname ?? "",
            athleteLastname: tokenResponse.athlete.lastname ?? "",
            updatedAt: ISO8601DateFormatter().string(from: Date())
        )
        
        let response = try await supabase.client
            .from("strava_connections")
            .upsert(connectionRequest)
            .select()
            .single()
            .execute()
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let connection = try decoder.decode(StravaConnection.self, from: response.data)
        
        print("✅ Strava connection stored for user: \(userId)")
        return connection
    }
    
    /// Update Strava connection with new tokens
    private func updateConnection(userId: UUID, tokenResponse: StravaRefreshResponse) async throws -> StravaConnection {
        let expiresAt = Date(timeIntervalSince1970: TimeInterval(tokenResponse.expiresAt))
        
        let updateRequest = StravaConnectionUpdateRequest(
            accessToken: tokenResponse.accessToken,
            refreshToken: tokenResponse.refreshToken,
            expiresAt: ISO8601DateFormatter().string(from: expiresAt),
            updatedAt: ISO8601DateFormatter().string(from: Date())
        )
        
        let response = try await supabase.client
            .from("strava_connections")
            .update(updateRequest)
            .eq("user_id", value: userId.uuidString)
            .select()
            .single()
            .execute()
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let connection = try decoder.decode(StravaConnection.self, from: response.data)
        
        print("✅ Strava connection updated for user: \(userId)")
        return connection
    }
    
    /// Fetch Strava connection for user
    /// - Parameter userId: User's ID
    /// - Returns: Strava connection if exists
    /// - Throws: Error if fetch fails
    func fetchConnection(userId: UUID) async throws -> StravaConnection? {
        do {
            let response = try await supabase.client
                .from("strava_connections")
                .select()
                .eq("user_id", value: userId.uuidString)
                .single()
                .execute()
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let connection = try decoder.decode(StravaConnection.self, from: response.data)
            
            print("✅ Strava connection fetched for user: \(userId)")
            return connection
            
        } catch {
            // No connection found is not an error
            print("ℹ️ No Strava connection found for user: \(userId)")
            return nil
        }
    }
    
    /// Disconnect Strava (delete connection)
    /// - Parameter userId: User's ID
    /// - Throws: Error if deletion fails
    func disconnect(userId: UUID) async throws {
        try await supabase.client
            .from("strava_connections")
            .delete()
            .eq("user_id", value: userId.uuidString)
            .execute()
        
        print("✅ Strava disconnected for user: \(userId)")
    }
    
    // MARK: - Activity Syncing
    
    /// Fetch activities from Strava API
    /// - Parameters:
    ///   - connection: Strava connection with valid access token
    ///   - page: Page number for pagination (default 1)
    ///   - perPage: Activities per page (default 30, max 200)
    /// - Returns: Array of Strava activity responses
    /// - Throws: Error if fetch fails
    func fetchActivitiesFromStrava(connection: StravaConnection, page: Int = 1, perPage: Int = 30) async throws -> [StravaActivityResponse] {
        // Check if token needs refresh
        var activeConnection = connection
        if connection.needsRefresh {
            print("🔄 Token expired, refreshing...")
            activeConnection = try await refreshToken(connection: connection)
        }
        
        let urlString = "\(Configuration.Strava.apiBaseUrl)/athlete/activities?page=\(page)&per_page=\(perPage)"
        guard let url = URL(string: urlString) else {
            throw StravaError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(activeConnection.accessToken)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw StravaError.invalidResponse
        }
        
        // Handle rate limiting
        if httpResponse.statusCode == 429 {
            throw StravaError.rateLimitExceeded
        }
        
        guard httpResponse.statusCode == 200 else {
            throw StravaError.apiError(httpResponse.statusCode)
        }
        
        let activities = try JSONDecoder().decode([StravaActivityResponse].self, from: data)
        print("✅ Fetched \(activities.count) activities from Strava")
        
        return activities
    }
    
    /// Sync activities from Strava to Supabase
    /// - Parameters:
    ///   - userId: User's ID
    ///   - connection: Strava connection
    /// - Returns: Number of activities synced
    /// - Throws: Error if sync fails
    func syncActivities(userId: UUID, connection: StravaConnection) async throws -> Int {
        let stravaActivities = try await fetchActivitiesFromStrava(connection: connection)
        
        var syncedCount = 0
        var affectedDates = Set<Date>()
        let calendar = Calendar.current
        
        for stravaActivity in stravaActivities {
            do {
                try await storeActivity(userId: userId, stravaActivity: stravaActivity)
                syncedCount += 1
                
                // Track the date for daily summary update
                let activityDate = calendar.startOfDay(for: stravaActivity.startDate)
                affectedDates.insert(activityDate)
            } catch {
                print("❌ Failed to store activity \(stravaActivity.id): \(error)")
                // Continue with next activity
            }
        }
        
        print("✅ Synced \(syncedCount) activities to database")
        
        // Update daily summaries for all affected dates
        if !affectedDates.isEmpty {
            print("📊 Updating daily summaries for \(affectedDates.count) date(s)")
            let summaryService = DailySummaryService()
            for date in affectedDates {
                do {
                    try await summaryService.updateExerciseCalories(userId: userId, date: date)
                } catch {
                    print("❌ Failed to update daily summary for \(date): \(error)")
                }
            }
        }
        
        return syncedCount
    }
    
    /// Store or update activity in Supabase
    private func storeActivity(userId: UUID, stravaActivity: StravaActivityResponse) async throws {
        let activityRequest = ActivityRequest(
            userId: userId.uuidString,
            stravaId: stravaActivity.id,
            name: stravaActivity.name,
            type: stravaActivity.type,
            startDate: ISO8601DateFormatter().string(from: stravaActivity.startDate),
            duration: stravaActivity.movingTime,
            distance: stravaActivity.distance ?? 0,
            calories: stravaActivity.calories ?? estimateCalories(activity: stravaActivity),
            averageSpeed: stravaActivity.averageSpeed,
            maxSpeed: stravaActivity.maxSpeed,
            averageHeartrate: stravaActivity.averageHeartrate,
            maxHeartrate: stravaActivity.maxHeartrate,
            elevationGain: stravaActivity.totalElevationGain
        )
        
        // Upsert based on user_id and strava_id
        _ = try await supabase.client
            .from("activities")
            .upsert(activityRequest)
            .execute()
    }
    
    /// Fetch activities from Supabase for user
    /// - Parameter userId: User's ID
    /// - Returns: Array of activities
    /// - Throws: Error if fetch fails
    func fetchActivitiesFromDatabase(userId: UUID) async throws -> [Activity] {
        let response = try await supabase.client
            .from("activities")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("start_date", ascending: false)
            .execute()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let activities = try decoder.decode([Activity].self, from: response.data)

        print("✅ Fetched \(activities.count) activities from database")
        return activities
    }

    /// Fetch activities from Supabase for user within date range
    /// - Parameters:
    ///   - userId: User's ID
    ///   - startDate: Start of date range
    ///   - endDate: End of date range
    /// - Returns: Array of activities
    /// - Throws: Error if fetch fails
    func fetchActivitiesFromDatabase(userId: UUID, startDate: Date, endDate: Date) async throws -> [Activity] {
        let response = try await supabase.client
            .from("activities")
            .select()
            .eq("user_id", value: userId.uuidString)
            .gte("start_date", value: startDate.ISO8601Format())
            .lte("start_date", value: endDate.ISO8601Format())
            .order("start_date", ascending: false)
            .execute()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let activities = try decoder.decode([Activity].self, from: response.data)

        print("✅ Fetched \(activities.count) activities from database for date range")
        return activities
    }
    
    // MARK: - Helper Methods
    
    /// Estimate calories if not provided by Strava
    private func estimateCalories(activity: StravaActivityResponse) -> Int {
        // Rough estimate: 50 calories per km for running, 30 for cycling
        guard let distance = activity.distance else { return 0 }
        
        let km = distance / 1000
        let caloriesPerKm: Double
        
        switch activity.type.lowercased() {
        case "run", "trail run", "virtual run":
            caloriesPerKm = 50
        case "ride", "virtual ride", "e-bike ride":
            caloriesPerKm = 30
        case "swim":
            caloriesPerKm = 100
        default:
            caloriesPerKm = 40
        }
        
        return Int(km * caloriesPerKm)
    }
}

// MARK: - Request/Response Models

/// Strava token refresh response (lighter than full token response)
private struct StravaRefreshResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresAt: Int
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresAt = "expires_at"
    }
}

/// Strava activity response from API
struct StravaActivityResponse: Codable {
    let id: Int64
    let name: String
    let type: String
    let startDate: Date
    let distance: Double?
    let movingTime: Int
    let elapsedTime: Int
    let totalElevationGain: Double?
    let averageSpeed: Double?
    let maxSpeed: Double?
    let averageHeartrate: Double?
    let maxHeartrate: Int?
    let calories: Int?
    
    enum CodingKeys: String, CodingKey {
        case id, name, type, distance, calories
        case startDate = "start_date"
        case movingTime = "moving_time"
        case elapsedTime = "elapsed_time"
        case totalElevationGain = "total_elevation_gain"
        case averageSpeed = "average_speed"
        case maxSpeed = "max_speed"
        case averageHeartrate = "average_heartrate"
        case maxHeartrate = "max_heartrate"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int64.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        type = try container.decode(String.self, forKey: .type)
        
        // Parse ISO8601 date string
        let dateString = try container.decode(String.self, forKey: .startDate)
        let formatter = ISO8601DateFormatter()
        startDate = formatter.date(from: dateString) ?? Date()
        
        distance = try container.decodeIfPresent(Double.self, forKey: .distance)
        movingTime = try container.decode(Int.self, forKey: .movingTime)
        elapsedTime = try container.decode(Int.self, forKey: .elapsedTime)
        totalElevationGain = try container.decodeIfPresent(Double.self, forKey: .totalElevationGain)
        averageSpeed = try container.decodeIfPresent(Double.self, forKey: .averageSpeed)
        maxSpeed = try container.decodeIfPresent(Double.self, forKey: .maxSpeed)
        averageHeartrate = try container.decodeIfPresent(Double.self, forKey: .averageHeartrate)
        maxHeartrate = try container.decodeIfPresent(Int.self, forKey: .maxHeartrate)
        calories = try container.decodeIfPresent(Int.self, forKey: .calories)
    }
}

/// Request struct for storing Strava connection
private struct StravaConnectionRequest: Codable {
    let userId: String
    let accessToken: String
    let refreshToken: String
    let expiresAt: String
    let athleteId: String
    let athleteUsername: String
    let athleteFirstname: String
    let athleteLastname: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresAt = "expires_at"
        case athleteId = "athlete_id"
        case athleteUsername = "athlete_username"
        case athleteFirstname = "athlete_firstname"
        case athleteLastname = "athlete_lastname"
        case updatedAt = "updated_at"
    }
}

/// Request struct for updating Strava connection
private struct StravaConnectionUpdateRequest: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresAt = "expires_at"
        case updatedAt = "updated_at"
    }
}

/// Request struct for storing activity
private struct ActivityRequest: Codable {
    let userId: String
    let stravaId: Int64
    let name: String
    let type: String
    let startDate: String
    let duration: Int
    let distance: Double
    let calories: Int
    let averageSpeed: Double?
    let maxSpeed: Double?
    let averageHeartrate: Double?
    let maxHeartrate: Int?
    let elevationGain: Double?
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case stravaId = "strava_id"
        case name, type
        case startDate = "start_date"
        case duration, distance, calories
        case averageSpeed = "average_speed"
        case maxSpeed = "max_speed"
        case averageHeartrate = "average_heartrate"
        case maxHeartrate = "max_heartrate"
        case elevationGain = "elevation_gain"
    }
}

// MARK: - Errors

enum StravaError: LocalizedError {
    case invalidURL
    case invalidResponse
    case tokenExchangeFailed(Int)
    case tokenRefreshFailed
    case rateLimitExceeded
    case apiError(Int)
    case noConnection
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid Strava API URL"
        case .invalidResponse:
            return "Invalid response from Strava"
        case .tokenExchangeFailed(let code):
            return "Failed to exchange authorization code (HTTP \(code))"
        case .tokenRefreshFailed:
            return "Failed to refresh Strava token"
        case .rateLimitExceeded:
            return "Strava API rate limit exceeded. Please try again later."
        case .apiError(let code):
            return "Strava API error (HTTP \(code))"
        case .noConnection:
            return "No Strava connection found. Please connect your Strava account."
        }
    }
}
