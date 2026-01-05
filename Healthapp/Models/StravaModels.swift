//
//  StravaModels.swift
//  Netfuel
//
//  Models for Strava API responses
//

import Foundation

/// Strava OAuth token response
struct StravaTokenResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresAt: Int
    let expiresIn: Int
    let athlete: StravaAthlete
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresAt = "expires_at"
        case expiresIn = "expires_in"
        case athlete
    }
}

/// Strava athlete information
struct StravaAthlete: Codable {
    let id: Int
    let username: String?
    let firstname: String?
    let lastname: String?
    let profile: String?
    
    var fullName: String {
        let first = firstname ?? ""
        let last = lastname ?? ""
        return "\(first) \(last)".trimmingCharacters(in: .whitespaces)
    }
}

/// Strava activity from API
struct StravaActivity: Codable {
    let id: Int
    let name: String
    let type: String
    let startDate: Date
    let distance: Double?
    let movingTime: Int
    let elapsedTime: Int
    let totalElevationGain: Double?
    let averageSpeed: Double?
    let maxSpeed: Double?
    let calories: Double?
    let averageHeartrate: Double?
    let maxHeartrate: Double?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case type
        case startDate = "start_date"
        case distance
        case movingTime = "moving_time"
        case elapsedTime = "elapsed_time"
        case totalElevationGain = "total_elevation_gain"
        case averageSpeed = "average_speed"
        case maxSpeed = "max_speed"
        case calories
        case averageHeartrate = "average_heartrate"
        case maxHeartrate = "max_heartrate"
    }
}

