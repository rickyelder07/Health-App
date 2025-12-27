//
//  Activity.swift
//  Health App
//
//  Model for exercise activities from Strava
//

import Foundation

/// Exercise activity synced from Strava
struct Activity: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    
    // Strava reference
    let stravaId: Int64 // BIGINT in database
    
    // Activity information
    var name: String
    var type: String // "Run", "Ride", "Swim", etc.
    var startDate: Date
    var duration: Int // in seconds
    var distance: Double? // in meters
    
    // Calorie information
    var calories: Int
    
    // Additional metrics
    var averageSpeed: Double? // in meters per second
    var maxSpeed: Double? // in meters per second
    var averageHeartrate: Double?
    var maxHeartrate: Int?
    var elevationGain: Double? // in meters
    
    // Timestamps
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case stravaId = "strava_id"
        case name
        case type
        case startDate = "start_date"
        case duration
        case distance
        case calories
        case averageSpeed = "average_speed"
        case maxSpeed = "max_speed"
        case averageHeartrate = "average_heartrate"
        case maxHeartrate = "max_heartrate"
        case elevationGain = "elevation_gain"
        case createdAt = "created_at"
    }

    
    /// Format duration as HH:MM:SS
    var formattedDuration: String {
        let hours = duration / 3600
        let minutes = duration / 60 % 60
        let seconds = duration % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    /// Format distance in km
    var formattedDistance: String? {
        guard let distance = distance else { return nil }
        let km = distance / 1000
        return String(format: "%.2f km", km)
    }
    
    /// Format average pace (min/km)
    var formattedPace: String? {
        guard let distance = distance, distance > 0 else { return nil }
        let paceSeconds = Double(duration) / (distance / 1000)
        let minutes = Int(paceSeconds) / 60
        let seconds = Int(paceSeconds) % 60
        return String(format: "%d:%02d /km", minutes, seconds)
    }
    
    /// Format average speed in km/h
    var formattedSpeed: String? {
        guard let speed = averageSpeed else { return nil }
        let kmh = speed * 3.6 // Convert m/s to km/h
        return String(format: "%.1f km/h", kmh)
    }
}

