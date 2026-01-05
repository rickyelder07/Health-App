//
//  ProgressPhotoViewModel.swift
//  Netfuel
//
//  ViewModel for managing progress photo state and operations
//

import Foundation
import UIKit
import Combine

/// ViewModel for progress photo management
@MainActor
class ProgressPhotoViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var photos: [ProgressPhoto] = []
    @Published var isLoading: Bool = false
    @Published var isUploading: Bool = false
    @Published var uploadProgress: Double = 0.0
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    // Filters
    @Published var startDate: Date?
    @Published var endDate: Date?
    
    // Selected photos for comparison
    @Published var selectedPhotos: [ProgressPhoto] = []
    
    // MARK: - Private Properties
    
    private let photoService = PhotoService()
    private var userId: UUID?
    
    // MARK: - Computed Properties
    
    var filteredPhotos: [ProgressPhoto] {
        guard let start = startDate, let end = endDate else {
            return photos
        }
        
        return photos.filter { photo in
            photo.takenAt >= start && photo.takenAt <= end
        }
    }
    
    var photosWithWeight: [ProgressPhoto] {
        photos.filter { $0.weight != nil }
    }
    
    var totalPhotoCount: Int {
        photos.count
    }
    
    // MARK: - Initialization
    
    func setUser(userId: UUID) {
        self.userId = userId
        Task {
            await loadPhotos()
        }
    }
    
    // MARK: - Photo Loading
    
    /// Load all photos for the user
    func loadPhotos() async {
        guard let userId = userId else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            if let start = startDate, let end = endDate {
                photos = try await photoService.fetchPhotos(
                    userId: userId,
                    startDate: start,
                    endDate: end
                )
            } else {
                photos = try await photoService.fetchPhotos(userId: userId)
            }
            
            print("✅ Loaded \(photos.count) photos")
        } catch {
            errorMessage = "Failed to load photos: \(error.localizedDescription)"
            print("❌ Photo loading error: \(error)")
        }
        
        isLoading = false
    }
    
    /// Refresh photos
    func refreshPhotos() async {
        await loadPhotos()
    }
    
    // MARK: - Photo Upload
    
    /// Upload a new progress photo
    func uploadPhoto(
        image: UIImage,
        weight: Double?,
        notes: String?,
        takenAt: Date
    ) async -> Bool {
        guard let userId = userId else {
            errorMessage = "User not authenticated"
            return false
        }

        isUploading = true
        uploadProgress = 0.0
        errorMessage = nil

        do {
            // Simulate progress (real progress tracking would need more complex implementation)
            uploadProgress = 0.3

            let photo = try await photoService.uploadPhoto(
                image: image,
                userId: userId,
                weight: weight,
                notes: notes,
                takenAt: takenAt
            )

            uploadProgress = 0.7

            // If weight was provided, sync it to users table and daily_summaries
            if let weightLbs = weight {
                // Convert lbs to kg for users/daily_summaries tables
                let weightKg = weightLbs * 0.453592

                // Update user's current weight
                _ = try await ProfileService.shared.updateWeight(userId: userId, weight: weightKg)

                // Update daily summary for the photo date
                try await DailySummaryService.shared.updateDailyWeight(
                    userId: userId,
                    date: takenAt,
                    weight: weightKg
                )
            }

            uploadProgress = 1.0

            // Add to local array
            photos.insert(photo, at: 0)

            successMessage = "Photo uploaded successfully!"
            isUploading = false

            return true

        } catch {
            errorMessage = "Upload failed: \(error.localizedDescription)"
            isUploading = false
            uploadProgress = 0.0
            return false
        }
    }
    
    // MARK: - Photo Updates
    
    /// Update photo metadata
    func updatePhoto(
        photoId: UUID,
        weight: Double?,
        notes: String?
    ) async -> Bool {
        guard let userId = userId else {
            errorMessage = "User not authenticated"
            return false
        }

        isLoading = true
        errorMessage = nil

        do {
            let updatedPhoto = try await photoService.updatePhoto(
                photoId: photoId,
                weight: weight,
                notes: notes
            )

            // If weight was updated, sync it to users table and daily_summaries
            if let weightLbs = weight {
                // Convert lbs to kg for users/daily_summaries tables
                let weightKg = weightLbs * 0.453592

                // Update user's current weight
                _ = try await ProfileService.shared.updateWeight(userId: userId, weight: weightKg)

                // Update daily summary for the photo date
                try await DailySummaryService.shared.updateDailyWeight(
                    userId: userId,
                    date: updatedPhoto.takenAt,
                    weight: weightKg
                )
            }

            // Update in local array
            if let index = photos.firstIndex(where: { $0.id == photoId }) {
                photos[index] = updatedPhoto
            }

            successMessage = "Photo updated"
            isLoading = false
            return true

        } catch {
            errorMessage = "Update failed: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    /// Delete a photo
    func deletePhoto(_ photo: ProgressPhoto) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            try await photoService.deletePhoto(photo: photo)
            
            // Remove from local array
            photos.removeAll { $0.id == photo.id }
            
            successMessage = "Photo deleted"
            isLoading = false
            return true
            
        } catch {
            errorMessage = "Delete failed: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    // MARK: - Photo Comparison
    
    /// Toggle photo selection for comparison
    func togglePhotoSelection(_ photo: ProgressPhoto) {
        if let index = selectedPhotos.firstIndex(where: { $0.id == photo.id }) {
            selectedPhotos.remove(at: index)
        } else if selectedPhotos.count < 2 {
            selectedPhotos.append(photo)
        }
    }
    
    /// Clear selected photos
    func clearSelection() {
        selectedPhotos.removeAll()
    }
    
    /// Check if photo is selected
    func isSelected(_ photo: ProgressPhoto) -> Bool {
        selectedPhotos.contains(where: { $0.id == photo.id })
    }
    
    /// Get weight difference between two photos
    func getWeightDifference() -> Double? {
        guard selectedPhotos.count == 2,
              let weight1 = selectedPhotos[0].weight,
              let weight2 = selectedPhotos[1].weight else {
            return nil
        }
        
        return weight2 - weight1
    }
    
    /// Get time difference between two photos
    func getTimeDifference() -> String? {
        guard selectedPhotos.count == 2 else { return nil }
        
        let date1 = selectedPhotos[0].takenAt
        let date2 = selectedPhotos[1].takenAt
        
        let interval = abs(date2.timeIntervalSince(date1))
        let days = Int(interval / 86400)
        
        if days < 7 {
            return "\(days) day\(days == 1 ? "" : "s")"
        } else if days < 30 {
            let weeks = days / 7
            return "\(weeks) week\(weeks == 1 ? "" : "s")"
        } else {
            let months = days / 30
            return "\(months) month\(months == 1 ? "" : "s")"
        }
    }
    
    // MARK: - Filters
    
    /// Apply date range filter
    func applyDateFilter(start: Date, end: Date) {
        startDate = start
        endDate = end
        
        Task {
            await loadPhotos()
        }
    }
    
    /// Clear date filters
    func clearFilters() {
        startDate = nil
        endDate = nil
        
        Task {
            await loadPhotos()
        }
    }
    
    // MARK: - Utility Methods
    
    /// Clear messages
    func clearMessages() {
        successMessage = nil
        errorMessage = nil
    }
    
    /// Get oldest and newest photo dates
    func getDateRange() -> (oldest: Date?, newest: Date?) {
        guard !photos.isEmpty else { return (nil, nil) }
        
        let sorted = photos.sorted { $0.takenAt < $1.takenAt }
        return (sorted.first?.takenAt, sorted.last?.takenAt)
    }
    
    /// Get photo count by month
    func getPhotoCountByMonth() -> [String: Int] {
        var counts: [String: Int] = [:]
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        
        for photo in photos {
            let key = formatter.string(from: photo.takenAt)
            counts[key, default: 0] += 1
        }
        
        return counts
    }
}

