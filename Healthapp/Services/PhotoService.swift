//
//  PhotoService.swift
//  Health App
//
//  Service for managing progress photos with Supabase Storage
//

import Foundation
import UIKit
import Supabase

/// Service for managing progress photo uploads and storage
class PhotoService {
    private let supabase = SupabaseClient.shared.client
    private let bucketName = "progress-photos"
    
    // MARK: - Photo Upload
    
    /// Upload a progress photo to Supabase Storage
    /// - Parameters:
    ///   - image: UIImage to upload
    ///   - userId: User ID for folder organization
    ///   - weight: Optional weight measurement
    ///   - notes: Optional notes
    ///   - takenAt: Date photo was taken
    /// - Returns: Created ProgressPhoto record
    func uploadPhoto(
        image: UIImage,
        userId: UUID,
        weight: Double?,
        notes: String?,
        takenAt: Date
    ) async throws -> ProgressPhoto {
        // DEBUG: Check authentication status
        do {
            let session = try await supabase.auth.session
            print("🔑 Current session user ID: \(session.user.id)")
            print("🔑 Session access token exists: \(session.accessToken.isEmpty == false)")
            print("🔑 Uploading to path: \(userId.uuidString)/...")
        } catch {
            print("❌ No active session! Error: \(error)")
            throw PhotoServiceError.uploadFailed("Not authenticated. Please log in again.")
        }
        
        // Compress image
        guard let compressedData = compressImage(image, maxSizeKB: 2048) else {
            throw PhotoServiceError.compressionFailed
        }
        
        // Generate unique filename
        let timestamp = Int(Date().timeIntervalSince1970)
        let filename = "\(userId.uuidString)/\(timestamp)_full.jpg"
        
        // Upload to Supabase Storage
        let photoPath = try await uploadToStorage(data: compressedData, path: filename)
        
        // Generate and upload thumbnail
        var thumbnailPath: String?
        if let thumbnailData = generateThumbnail(from: image, maxSize: 300) {
            let thumbFilename = "\(userId.uuidString)/\(timestamp)_thumb.jpg"
            thumbnailPath = try await uploadToStorage(data: thumbnailData, path: thumbFilename)
        }
        
        // Store the paths (not URLs) in the database
        // We'll generate signed URLs when fetching photos
        // This way URLs don't expire in the database
        
        // Save metadata to database with storage paths
        return try await savePhotoMetadata(
            userId: userId,
            photoURL: photoPath,  // Store path, not URL
            thumbnailURL: thumbnailPath,  // Store path, not URL
            weight: weight,
            notes: notes,
            takenAt: takenAt
        )
    }
    
    /// Upload data to Supabase Storage
    private func uploadToStorage(data: Data, path: String) async throws -> String {
        do {
            _ = try await supabase.storage
                .from(bucketName)
                .upload(
                    path: path,
                    file: data,
                    options: FileOptions(contentType: "image/jpeg")
                )
            
            print("✅ Photo uploaded to: \(path)")
            return path
            
        } catch {
            print("❌ Failed to upload photo: \(error)")
            throw PhotoServiceError.uploadFailed(error.localizedDescription)
        }
    }
    
    /// Get signed URL for a file in storage (for private buckets)
    /// Signed URLs expire after a set time and include authentication
    private func getSignedURL(path: String, expiresIn: Int = 3600) async throws -> String {
        let signedURL = try await supabase.storage
            .from(bucketName)
            .createSignedURL(path: path, expiresIn: expiresIn)
        
        return signedURL.absoluteString
    }
    
    // MARK: - Image Processing
    
    /// Compress image to target size
    private func compressImage(_ image: UIImage, maxSizeKB: Int) -> Data? {
        let maxBytes = maxSizeKB * 1024
        var compression: CGFloat = 0.8
        var imageData = image.jpegData(compressionQuality: compression)
        
        // Iteratively reduce quality if needed
        while let data = imageData, data.count > maxBytes && compression > 0.1 {
            compression -= 0.1
            imageData = image.jpegData(compressionQuality: compression)
        }
        
        return imageData
    }
    
    /// Generate thumbnail from image
    private func generateThumbnail(from image: UIImage, maxSize: CGFloat) -> Data? {
        let scale = min(maxSize / image.size.width, maxSize / image.size.height)
        let newSize = CGSize(
            width: image.size.width * scale,
            height: image.size.height * scale
        )
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let thumbnail = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return thumbnail?.jpegData(compressionQuality: 0.7)
    }
    
    // MARK: - Database Operations
    
    /// Save photo metadata to database
    private func savePhotoMetadata(
        userId: UUID,
        photoURL: String,
        thumbnailURL: String?,
        weight: Double?,
        notes: String?,
        takenAt: Date
    ) async throws -> ProgressPhoto {
        let request = CreateProgressPhotoRequest(
            userId: userId,
            photoUrl: photoURL,
            thumbnailUrl: thumbnailURL,
            weight: weight,
            notes: notes,
            takenAt: takenAt
        )
        
        let response = try await supabase
            .from("progress_photos")
            .insert(request)
            .select()
            .execute()
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let photos = try decoder.decode([ProgressPhoto].self, from: response.data)
        
        guard let photo = photos.first else {
            throw PhotoServiceError.saveFailed
        }
        
        print("✅ Photo metadata saved to database")
        return photo
    }
    
    /// Fetch all progress photos for a user
    func fetchPhotos(userId: UUID) async throws -> [ProgressPhoto] {
        let response = try await supabase
            .from("progress_photos")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("taken_at", ascending: false)
            .execute()
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        var photos = try decoder.decode([ProgressPhoto].self, from: response.data)
        
        // Generate fresh signed URLs for each photo
        for i in 0..<photos.count {
            // The photoUrl field contains the storage path, generate signed URL
            let signedPhotoURL = try await getSignedURL(path: photos[i].photoUrl, expiresIn: 3600)
            photos[i].photoUrl = signedPhotoURL
            
            // Generate signed URL for thumbnail if it exists
            if let thumbnailPath = photos[i].thumbnailUrl {
                let signedThumbnailURL = try await getSignedURL(path: thumbnailPath, expiresIn: 3600)
                photos[i].thumbnailUrl = signedThumbnailURL
            }
        }
        
        return photos
    }
    
    /// Fetch photos within date range
    func fetchPhotos(
        userId: UUID,
        startDate: Date,
        endDate: Date
    ) async throws -> [ProgressPhoto] {
        let response = try await supabase
            .from("progress_photos")
            .select()
            .eq("user_id", value: userId.uuidString)
            .gte("taken_at", value: startDate.ISO8601Format())
            .lte("taken_at", value: endDate.ISO8601Format())
            .order("taken_at", ascending: false)
            .execute()
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        var photos = try decoder.decode([ProgressPhoto].self, from: response.data)
        
        // Generate fresh signed URLs for each photo
        for i in 0..<photos.count {
            let signedPhotoURL = try await getSignedURL(path: photos[i].photoUrl, expiresIn: 3600)
            photos[i].photoUrl = signedPhotoURL
            
            if let thumbnailPath = photos[i].thumbnailUrl {
                let signedThumbnailURL = try await getSignedURL(path: thumbnailPath, expiresIn: 3600)
                photos[i].thumbnailUrl = signedThumbnailURL
            }
        }
        
        return photos
    }
    
    /// Update photo metadata
    func updatePhoto(
        photoId: UUID,
        weight: Double?,
        notes: String?
    ) async throws -> ProgressPhoto {
        let request = UpdateProgressPhotoRequest(
            weight: weight,
            notes: notes
        )
        
        let response = try await supabase
            .from("progress_photos")
            .update(request)
            .eq("id", value: photoId.uuidString)
            .select()
            .execute()
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let photos = try decoder.decode([ProgressPhoto].self, from: response.data)
        
        guard let photo = photos.first else {
            throw PhotoServiceError.updateFailed
        }
        
        return photo
    }
    
    /// Delete photo and its files from storage
    func deletePhoto(photo: ProgressPhoto) async throws {
        // Extract file paths from URLs
        let photoPath = extractPath(from: photo.photoUrl)
        let thumbnailPath = photo.thumbnailUrl.flatMap { extractPath(from: $0) }
        
        // Delete files from storage
        var filesToDelete: [String] = [photoPath]
        if let thumbPath = thumbnailPath {
            filesToDelete.append(thumbPath)
        }
        
        do {
            _ = try await supabase.storage
                .from(bucketName)
                .remove(paths: filesToDelete)
            
            print("✅ Photo files deleted from storage")
        } catch {
            print("⚠️ Failed to delete files from storage: \(error)")
            // Continue to delete database record even if storage deletion fails
        }
        
        // Delete metadata from database
        try await supabase
            .from("progress_photos")
            .delete()
            .eq("id", value: photo.id.uuidString)
            .execute()
        
        print("✅ Photo metadata deleted from database")
    }
    
    /// Extract file path from public URL
    private func extractPath(from url: String) -> String {
        // URL format: https://xxx.supabase.co/storage/v1/object/public/progress-photos/path/to/file.jpg
        // Extract: path/to/file.jpg
        if let range = url.range(of: "/\(bucketName)/") {
            return String(url[range.upperBound...])
        }
        return url
    }
    
    // MARK: - Statistics
    
    /// Get photo count for user
    func getPhotoCount(userId: UUID) async throws -> Int {
        let response = try await supabase
            .from("progress_photos")
            .select("id", head: true, count: .exact)
            .eq("user_id", value: userId.uuidString)
            .execute()
        
        return response.count ?? 0
    }
}

// MARK: - Supporting Models

/// Request model for creating progress photo
struct CreateProgressPhotoRequest: Codable {
    let userId: UUID
    let photoUrl: String
    let thumbnailUrl: String?
    let weight: Double?
    let notes: String?
    let takenAt: Date
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case photoUrl = "photo_url"
        case thumbnailUrl = "thumbnail_url"
        case weight
        case notes
        case takenAt = "taken_at"
    }
}

/// Request model for updating progress photo
struct UpdateProgressPhotoRequest: Codable {
    let weight: Double?
    let notes: String?
    
    enum CodingKeys: String, CodingKey {
        case weight
        case notes
    }
}

// MARK: - Error Handling

/// Photo service errors
enum PhotoServiceError: LocalizedError {
    case compressionFailed
    case uploadFailed(String)
    case saveFailed
    case updateFailed
    case deleteFailed
    case invalidURL
    
    var errorDescription: String? {
        switch self {
        case .compressionFailed:
            return "Failed to compress image"
        case .uploadFailed(let message):
            return "Upload failed: \(message)"
        case .saveFailed:
            return "Failed to save photo metadata"
        case .updateFailed:
            return "Failed to update photo"
        case .deleteFailed:
            return "Failed to delete photo"
        case .invalidURL:
            return "Invalid photo URL"
        }
    }
}

