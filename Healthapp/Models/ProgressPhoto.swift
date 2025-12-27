//
//  ProgressPhoto.swift
//  Health App
//
//  Model for progress photo tracking
//

import Foundation

/// Progress photo for tracking visual changes over time
struct ProgressPhoto: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    
    // Photo information
    var photoUrl: String // Supabase Storage URL
    
    // Optional metadata
    var weight: Double? // Weight at time of photo (kg)
    var notes: String?
    
    // Timestamps
    let dateTaken: Date
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case photoUrl = "photo_url"
        case weight
        case notes
        case dateTaken = "date_taken"
        case createdAt = "created_at"
    }
    
    /// Format date for display
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: dateTaken)
    }
}

