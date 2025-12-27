//
//  StravaConnection.swift
//  Health App
//
//  Model for Strava OAuth connection and athlete information
//

import Foundation

/// Strava OAuth connection for syncing activities
struct StravaConnection: Codable, Identifiable {
    var id: UUID { userId } // Primary key is user_id
    let userId: UUID
    
    // OAuth tokens
    var accessToken: String
    var refreshToken: String
    var expiresAt: Date
    
    // Athlete information from Strava
    var athleteId: String
    var athleteUsername: String?
    var athleteFirstname: String?
    var athleteLastname: String?
    
    // Timestamps
    let connectedAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresAt = "expires_at"
        case athleteId = "athlete_id"
        case athleteUsername = "athlete_username"
        case athleteFirstname = "athlete_firstname"
        case athleteLastname = "athlete_lastname"
        case connectedAt = "connected_at"
        case updatedAt = "updated_at"
    }
    
    /// Check if the access token is expired or about to expire (within 5 minutes)
    var needsRefresh: Bool {
        return expiresAt.timeIntervalSinceNow < 300 // 5 minutes buffer
    }
    
    /// Full athlete name
    var athleteFullName: String? {
        guard let firstname = athleteFirstname, let lastname = athleteLastname else {
            return athleteUsername
        }
        return "\(firstname) \(lastname)"
    }
}

