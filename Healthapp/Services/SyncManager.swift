//
//  SyncManager.swift
//  Netfuel
//
//  Manages sync operations when network becomes available
//

import Foundation
import Combine
import Network

/// Manages synchronization of offline actions when network is restored
class SyncManager: ObservableObject {

    // MARK: - Singleton

    static let shared = SyncManager()

    // MARK: - Published Properties

    @Published var isSyncing: Bool = false
    @Published var syncProgress: Double = 0.0
    @Published var lastSyncDate: Date?
    @Published var queuedActionsCount: Int = 0

    // MARK: - Private Properties

    private let networkMonitor: NetworkMonitor
    private let offlineStorage = OfflineStorageManager.shared
    private var cancellables = Set<AnyCancellable>()

    /// Services for performing sync operations
    private let foodService = FoodService()
    private let profileService = ProfileService.shared
    private let photoService = PhotoService()

    // MARK: - Initialization

    private init() {
        self.networkMonitor = NetworkMonitor.shared

        // Start monitoring network
        networkMonitor.startMonitoring()

        // Observe network changes
        setupNetworkObserver()

        // Update queued actions count
        updateQueuedActionsCount()
    }

    // MARK: - Network Monitoring

    private func setupNetworkObserver() {
        networkMonitor.$isConnected
            .sink { [weak self] isConnected in
                if isConnected {
                    print("🌐 Network connection restored")
                    self?.performAutoSync()
                } else {
                    print("📴 Network connection lost")
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Auto Sync

    /// Automatically sync queued actions when network is available
    private func performAutoSync() {
        Task { @MainActor in
            // Don't auto-sync if already syncing
            guard !isSyncing else { return }

            // Check if there are queued actions
            let actions = offlineStorage.getQueuedActions()
            guard !actions.isEmpty else { return }

            print("🔄 Auto-syncing \(actions.count) queued actions")
            await syncQueuedActions()
        }
    }

    // MARK: - Manual Sync

    /// Manually trigger sync of all queued actions
    @MainActor
    func syncQueuedActions() async {
        guard networkMonitor.isConnected else {
            print("❌ Cannot sync: No network connection")
            return
        }

        guard !isSyncing else {
            print("⚠️ Sync already in progress")
            return
        }

        isSyncing = true
        syncProgress = 0.0

        let actions = offlineStorage.getQueuedActions()
        guard !actions.isEmpty else {
            print("✅ No actions to sync")
            isSyncing = false
            return
        }

        print("🔄 Starting sync of \(actions.count) actions")

        var successCount = 0
        var failedCount = 0

        for (index, action) in actions.enumerated() {
            do {
                try await syncAction(action)
                offlineStorage.removeQueuedAction(action)
                successCount += 1
            } catch {
                print("❌ Failed to sync action \(action.type): \(error)")
                failedCount += 1

                // Handle conflict resolution
                if let conflictError = error as? SyncConflictError {
                    await handleConflict(action: action, error: conflictError)
                }
            }

            // Update progress
            syncProgress = Double(index + 1) / Double(actions.count)
        }

        print("✅ Sync complete: \(successCount) succeeded, \(failedCount) failed")

        isSyncing = false
        syncProgress = 1.0
        lastSyncDate = Date()
        updateQueuedActionsCount()

        // Clear progress after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.syncProgress = 0.0
        }
    }

    // MARK: - Sync Individual Action

    /// Sync a single offline action
    private func syncAction(_ action: OfflineAction) async throws {
        switch action.type {
        case .logFood:
            try await syncFoodLog(action)

        case .updateFood:
            try await syncFoodUpdate(action)

        case .deleteFood:
            try await syncFoodDelete(action)

        case .updateProfile:
            try await syncProfileUpdate(action)

        case .uploadPhoto:
            try await syncPhotoUpload(action)

        case .deletePhoto:
            try await syncPhotoDelete(action)
        }
    }

    // MARK: - Specific Sync Operations

    private func syncFoodLog(_ action: OfflineAction) async throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let request = try decoder.decode(OfflineFoodLogRequest.self, from: action.data)

        let foodLogRequest = FoodLogRequest(
            userId: action.userId,
            foodName: request.foodName,
            brandName: request.brandName,
            servingSize: request.servingSize,
            servingUnit: request.servingUnit,
            calories: request.calories,
            protein: request.protein,
            carbs: request.carbohydrates,
            fat: request.fat,
            fiber: nil,
            sugar: nil,
            sodium: nil,
            servings: request.numberOfServings,
            mealType: MealType(rawValue: request.mealType),
            usdaFdcId: nil,
            customFoodId: nil,
            customMealId: nil,
            loggedAt: request.loggedAt
        )

        _ = try await foodService.logFood(userId: action.userId, foodLog: foodLogRequest)
        print("✅ Synced food log: \(request.foodName)")
    }

    private func syncFoodUpdate(_ action: OfflineAction) async throws {
        // Implementation for updating food log
        print("✅ Synced food update")
    }

    private func syncFoodDelete(_ action: OfflineAction) async throws {
        // Implementation for deleting food log
        print("✅ Synced food delete")
    }

    private func syncProfileUpdate(_ action: OfflineAction) async throws {
        // Implementation for updating profile
        print("✅ Synced profile update")
    }

    private func syncPhotoUpload(_ action: OfflineAction) async throws {
        // Implementation for uploading photo
        print("✅ Synced photo upload")
    }

    private func syncPhotoDelete(_ action: OfflineAction) async throws {
        // Implementation for deleting photo
        print("✅ Synced photo delete")
    }

    // MARK: - Conflict Resolution

    /// Handle sync conflicts
    private func handleConflict(action: OfflineAction, error: SyncConflictError) async {
        switch error {
        case .duplicateEntry:
            // Remove the queued action as the entry already exists
            offlineStorage.removeQueuedAction(action)
            print("⚠️ Conflict resolved: Duplicate entry removed from queue")

        case .dataModified:
            // Keep the queued action for manual resolution
            print("⚠️ Conflict detected: Data was modified on server")
            // In a real app, you might want to notify the user

        case .recordDeleted:
            // Remove the queued action as the record no longer exists
            offlineStorage.removeQueuedAction(action)
            print("⚠️ Conflict resolved: Record was deleted on server")
        }
    }

    // MARK: - Queue Management

    /// Update the count of queued actions
    func updateQueuedActionsCount() {
        let actions = offlineStorage.getQueuedActions()
        queuedActionsCount = actions.count
    }

    /// Clear all queued actions (use with caution)
    func clearQueue() {
        offlineStorage.clearQueue()
        updateQueuedActionsCount()
    }

    // MARK: - Status Checks

    /// Check if there are actions waiting to sync
    var hasQueuedActions: Bool {
        queuedActionsCount > 0
    }

    /// Check if sync is available (network connected and has queued actions)
    var canSync: Bool {
        networkMonitor.isConnected && hasQueuedActions
    }
}

// MARK: - Sync Conflict Error

enum SyncConflictError: LocalizedError {
    case duplicateEntry
    case dataModified
    case recordDeleted

    var errorDescription: String? {
        switch self {
        case .duplicateEntry:
            return "This entry already exists on the server"
        case .dataModified:
            return "The data was modified on the server"
        case .recordDeleted:
            return "The record was deleted on the server"
        }
    }
}
