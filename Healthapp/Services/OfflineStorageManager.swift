//
//  OfflineStorageManager.swift
//  Netfuel
//
//  Manages offline data caching and queueing for network resilience
//

import Foundation

/// Manages offline storage for data caching and queue management
class OfflineStorageManager {

    // MARK: - Singleton

    static let shared = OfflineStorageManager()

    // MARK: - Properties

    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    private let queueDirectory: URL

    /// Serial queue for thread-safe file operations
    private let fileQueue = DispatchQueue(label: "com.netfuel.offlineStorage", qos: .utility)

    // MARK: - Cache Keys

    private enum CacheKey {
        static let dailySummaries = "daily_summaries"
        static let foodLogs = "food_logs"
        static let activities = "activities"
        static let user = "user_profile"
    }

    // MARK: - Initialization

    private init() {
        // Set up cache directory
        let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        cacheDirectory = documentDirectory.appendingPathComponent("OfflineCache")
        queueDirectory = documentDirectory.appendingPathComponent("OfflineQueue")

        // Create directories if they don't exist
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: queueDirectory, withIntermediateDirectories: true)

        print("📂 Offline storage initialized")
        print("   Cache: \(cacheDirectory.path)")
        print("   Queue: \(queueDirectory.path)")
    }

    // MARK: - Daily Summaries Caching

    /// Cache daily summaries for offline viewing
    func cacheDailySummaries(_ summaries: [DailySummary], for userId: UUID) {
        fileQueue.async { [weak self] in
            guard let self = self else { return }

            do {
                let data = try JSONEncoder().encode(summaries)
                let fileURL = self.cacheURL(for: CacheKey.dailySummaries, userId: userId)
                try data.write(to: fileURL)

                print("✅ Cached \(summaries.count) daily summaries")
            } catch {
                print("❌ Failed to cache daily summaries: \(error)")
            }
        }
    }

    /// Load cached daily summaries
    func loadCachedDailySummaries(for userId: UUID) -> [DailySummary]? {
        let fileURL = cacheURL(for: CacheKey.dailySummaries, userId: userId)

        guard let data = try? Data(contentsOf: fileURL),
              let summaries = try? JSONDecoder().decode([DailySummary].self, from: data) else {
            return nil
        }

        print("📦 Loaded \(summaries.count) cached daily summaries")
        return summaries
    }

    // MARK: - Food Logs Caching

    /// Cache food logs for offline viewing
    func cacheFoodLogs(_ logs: [FoodLog], for userId: UUID) {
        fileQueue.async { [weak self] in
            guard let self = self else { return }

            do {
                let data = try JSONEncoder().encode(logs)
                let fileURL = self.cacheURL(for: CacheKey.foodLogs, userId: userId)
                try data.write(to: fileURL)

                print("✅ Cached \(logs.count) food logs")
            } catch {
                print("❌ Failed to cache food logs: \(error)")
            }
        }
    }

    /// Load cached food logs
    func loadCachedFoodLogs(for userId: UUID) -> [FoodLog]? {
        let fileURL = cacheURL(for: CacheKey.foodLogs, userId: userId)

        guard let data = try? Data(contentsOf: fileURL),
              let logs = try? JSONDecoder().decode([FoodLog].self, from: data) else {
            return nil
        }

        print("📦 Loaded \(logs.count) cached food logs")
        return logs
    }

    // MARK: - Activities Caching

    /// Cache activities for offline viewing
    func cacheActivities(_ activities: [Activity], for userId: UUID) {
        fileQueue.async { [weak self] in
            guard let self = self else { return }

            do {
                let data = try JSONEncoder().encode(activities)
                let fileURL = self.cacheURL(for: CacheKey.activities, userId: userId)
                try data.write(to: fileURL)

                print("✅ Cached \(activities.count) activities")
            } catch {
                print("❌ Failed to cache activities: \(error)")
            }
        }
    }

    /// Load cached activities
    func loadCachedActivities(for userId: UUID) -> [Activity]? {
        let fileURL = cacheURL(for: CacheKey.activities, userId: userId)

        guard let data = try? Data(contentsOf: fileURL),
              let activities = try? JSONDecoder().decode([Activity].self, from: data) else {
            return nil
        }

        print("📦 Loaded \(activities.count) cached activities")
        return activities
    }

    // MARK: - User Profile Caching

    /// Cache user profile for offline access
    func cacheUserProfile(_ user: User, for userId: UUID) {
        fileQueue.async { [weak self] in
            guard let self = self else { return }

            do {
                let data = try JSONEncoder().encode(user)
                let fileURL = self.cacheURL(for: CacheKey.user, userId: userId)
                try data.write(to: fileURL)

                print("✅ Cached user profile")
            } catch {
                print("❌ Failed to cache user profile: \(error)")
            }
        }
    }

    /// Load cached user profile
    func loadCachedUserProfile(for userId: UUID) -> User? {
        let fileURL = cacheURL(for: CacheKey.user, userId: userId)

        guard let data = try? Data(contentsOf: fileURL),
              let user = try? JSONDecoder().decode(User.self, from: data) else {
            return nil
        }

        print("📦 Loaded cached user profile")
        return user
    }

    // MARK: - Offline Queue Management

    /// Queue an offline action for later sync
    func queueOfflineAction(_ action: OfflineAction) {
        fileQueue.async { [weak self] in
            guard let self = self else { return }

            do {
                let data = try JSONEncoder().encode(action)
                let filename = "\(UUID().uuidString).json"
                let fileURL = self.queueDirectory.appendingPathComponent(filename)
                try data.write(to: fileURL)

                print("✅ Queued offline action: \(action.type)")
            } catch {
                print("❌ Failed to queue offline action: \(error)")
            }
        }
    }

    /// Get all queued offline actions
    func getQueuedActions() -> [OfflineAction] {
        var actions: [OfflineAction] = []

        do {
            let files = try fileManager.contentsOfDirectory(at: queueDirectory, includingPropertiesForKeys: nil)

            for file in files {
                if let data = try? Data(contentsOf: file),
                   let action = try? JSONDecoder().decode(OfflineAction.self, from: data) {
                    actions.append(action)
                }
            }
        } catch {
            print("❌ Failed to load queued actions: \(error)")
        }

        print("📦 Loaded \(actions.count) queued actions")
        return actions
    }

    /// Remove a queued action after successful sync
    func removeQueuedAction(_ action: OfflineAction) {
        fileQueue.async { [weak self] in
            guard let self = self else { return }

            do {
                let files = try self.fileManager.contentsOfDirectory(at: self.queueDirectory, includingPropertiesForKeys: nil)

                for file in files {
                    if let data = try? Data(contentsOf: file),
                       let queuedAction = try? JSONDecoder().decode(OfflineAction.self, from: data),
                       queuedAction.id == action.id {
                        try self.fileManager.removeItem(at: file)
                        print("✅ Removed queued action: \(action.type)")
                        break
                    }
                }
            } catch {
                print("❌ Failed to remove queued action: \(error)")
            }
        }
    }

    /// Clear all queued actions
    func clearQueue() {
        fileQueue.async { [weak self] in
            guard let self = self else { return }

            do {
                try self.fileManager.removeItem(at: self.queueDirectory)
                try self.fileManager.createDirectory(at: self.queueDirectory, withIntermediateDirectories: true)
                print("🧹 Offline queue cleared")
            } catch {
                print("❌ Failed to clear queue: \(error)")
            }
        }
    }

    // MARK: - Cache Management

    /// Clear all cached data
    func clearAllCache() {
        fileQueue.async { [weak self] in
            guard let self = self else { return }

            do {
                try self.fileManager.removeItem(at: self.cacheDirectory)
                try self.fileManager.createDirectory(at: self.cacheDirectory, withIntermediateDirectories: true)
                print("🧹 All cache cleared")
            } catch {
                print("❌ Failed to clear cache: \(error)")
            }
        }
    }

    /// Clear cache for specific user
    func clearCache(for userId: UUID) {
        fileQueue.async { [weak self] in
            guard let self = self else { return }

            let keys = [
                CacheKey.dailySummaries,
                CacheKey.foodLogs,
                CacheKey.activities,
                CacheKey.user
            ]

            for key in keys {
                let fileURL = self.cacheURL(for: key, userId: userId)
                try? self.fileManager.removeItem(at: fileURL)
            }

            print("🧹 Cache cleared for user: \(userId)")
        }
    }

    /// Get cache size in bytes
    func getCacheSize() -> Int {
        var size = 0

        do {
            let files = try fileManager.contentsOfDirectory(
                at: cacheDirectory,
                includingPropertiesForKeys: [.fileSizeKey]
            )

            for file in files {
                let fileSize = try file.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
                size += fileSize
            }
        } catch {
            print("❌ Failed to calculate cache size: \(error)")
        }

        return size
    }

    // MARK: - Private Helpers

    /// Generate cache file URL for a given key and user
    private func cacheURL(for key: String, userId: UUID) -> URL {
        return cacheDirectory.appendingPathComponent("\(userId.uuidString)_\(key).json")
    }
}

// MARK: - Offline Action Model

/// Represents an action to be performed when network is available
struct OfflineAction: Codable, Identifiable {
    let id: UUID
    let type: ActionType
    let data: Data
    let timestamp: Date
    let userId: UUID

    init(type: ActionType, data: Data, userId: UUID) {
        self.id = UUID()
        self.type = type
        self.data = data
        self.timestamp = Date()
        self.userId = userId
    }

    enum ActionType: String, Codable {
        case logFood
        case updateFood
        case deleteFood
        case updateProfile
        case uploadPhoto
        case deletePhoto
    }
}

// MARK: - Offline Food Log Request

/// Offline food log request model
struct OfflineFoodLogRequest: Codable {
    let foodName: String
    let brandName: String?
    let servingSize: String
    let servingUnit: String
    let numberOfServings: Double
    let calories: Int
    let protein: Double
    let carbohydrates: Double
    let fat: Double
    let mealType: String
    let loggedAt: Date
}
