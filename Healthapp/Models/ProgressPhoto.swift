//
//  ProgressPhoto.swift
//  Netfuel
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
    var thumbnailUrl: String? // Thumbnail URL

    // Optional metadata
    var weight: Double? // Weight at time of photo (lbs)
    var notes: String?

    // Timestamps
    let takenAt: Date // Date photo was taken
    let createdAt: Date
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case photoUrl = "photo_url"
        case thumbnailUrl = "thumbnail_url"
        case weight
        case notes
        case takenAt = "date_taken"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    /// Format date for display
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: takenAt)
    }
}

