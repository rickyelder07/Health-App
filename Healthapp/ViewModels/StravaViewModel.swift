//
//  StravaViewModel.swift
//  Health App
//
//  ViewModel for managing Strava connection and activity syncing
//

import Foundation
import Combine

/// ViewModel for Strava integration
@MainActor
class StravaViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var connection: StravaConnection?
    @Published var activities: [Activity] = []
    @Published var isConnected: Bool = false
    @Published var isLoading: Bool = false
    @Published var isSyncing: Bool = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    private let stravaService = StravaService()
    private let userId: UUID
    
    // MARK: - Initialization
    
    init(userId: UUID) {
        self.userId = userId
        Task {
            await loadConnection()
        }
    }
    
    // MARK: - Connection Management
    
    /// Load Strava connection from database
    func loadConnection() async {
        print("📥 Loading Strava connection for user: \(userId)")
        isLoading = true
        errorMessage = nil
        
        do {
            connection = try await stravaService.fetchConnection(userId: userId)
            isConnected = connection != nil
            
            if isConnected {
                print("✅ Strava is connected")
                if let conn = connection {
                    print("   - Athlete: \(conn.athleteFullName ?? "Unknown")")
                    print("   - Token expires: \(conn.expiresAt)")
                    print("   - Needs refresh: \(conn.needsRefresh)")
                }
                // Load activities if connected
                await loadActivities()
            } else {
                print("ℹ️ Strava is not connected")
            }
        } catch {
            errorMessage = "Failed to load Strava connection: \(error.localizedDescription)"
            print("❌ Failed to load connection: \(error)")
        }
        
        isLoading = false
        print("📥 Load connection complete. isConnected: \(isConnected)")
    }
    
    /// Start OAuth authorization flow
    func connectStrava() {
        print("🔵 Starting Strava OAuth flow")
        isLoading = true
        errorMessage = nil
        
        stravaService.startOAuthFlow(userId: userId) { [weak self] result in
            Task { @MainActor in
                guard let self = self else { return }
                
                switch result {
                case .success(let code):
                    print("✅ OAuth completed, exchanging code for token")
                    await self.handleOAuthCallback(code: code)
                    
                case .failure(let error):
                    print("❌ OAuth failed: \(error)")
                    self.errorMessage = "Failed to connect: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    /// Handle OAuth callback with authorization code
    /// - Parameter code: Authorization code from Strava
    func handleOAuthCallback(code: String) async {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        do {
            connection = try await stravaService.exchangeToken(code: code, userId: userId)
            isConnected = true
            successMessage = "Successfully connected to Strava!"
            print("✅ Strava connection successful")
            
            // Sync activities after connecting
            await syncActivities()
        } catch {
            errorMessage = "Failed to connect Strava: \(error.localizedDescription)"
            print("❌ OAuth callback failed: \(error)")
        }
        
        isLoading = false
    }
    
    /// Disconnect from Strava
    func disconnect() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await stravaService.disconnect(userId: userId)
            connection = nil
            isConnected = false
            activities = []
            successMessage = "Strava disconnected"
            print("✅ Strava disconnected")
        } catch {
            errorMessage = "Failed to disconnect: \(error.localizedDescription)"
            print("❌ Failed to disconnect: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Activity Management
    
    /// Sync activities from Strava
    func syncActivities() async {
        print("🔄 syncActivities() called")
        print("   - isConnected: \(isConnected)")
        print("   - connection: \(connection != nil ? "exists" : "nil")")
        
        guard let connection = connection else {
            errorMessage = "Not connected to Strava. Please connect your account first."
            print("❌ Cannot sync: Not connected to Strava")
            return
        }
        
        isSyncing = true
        errorMessage = nil
        successMessage = nil
        print("🔄 Starting Strava sync...")
        
        do {
            let syncedCount = try await stravaService.syncActivities(userId: userId, connection: connection)
            
            // Reload activities from database
            await loadActivities()
            
            successMessage = "Synced \(syncedCount) activities"
            print("✅ Synced \(syncedCount) activities")
        } catch StravaError.rateLimitExceeded {
            errorMessage = "Strava rate limit exceeded. Please wait 15 minutes and try again."
            print("❌ Rate limit exceeded")
        } catch {
            errorMessage = "Failed to sync activities: \(error.localizedDescription)"
            print("❌ Failed to sync activities: \(error)")
        }
        
        isSyncing = false
        print("🔄 Sync complete. isSyncing: \(isSyncing)")
    }
    
    /// Load activities from database
    func loadActivities() async {
        do {
            activities = try await stravaService.fetchActivitiesFromDatabase(userId: userId)
            print("✅ Loaded \(activities.count) activities")
        } catch {
            errorMessage = "Failed to load activities: \(error.localizedDescription)"
            print("❌ Failed to load activities: \(error)")
        }
    }
    
    /// Refresh activities (pull to refresh)
    func refreshActivities() async {
        guard isConnected else { return }
        await syncActivities()
    }
    
    // MARK: - Helper Methods
    
    /// Clear messages
    func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }
    
    /// Get connection status text
    var connectionStatusText: String {
        if isLoading {
            return "Loading..."
        } else if isConnected, let connection = connection {
            return "Connected as \(connection.athleteFullName ?? "Unknown")"
        } else {
            return "Not Connected"
        }
    }
    
    /// Get sync button text
    var syncButtonText: String {
        if isSyncing {
            return "Syncing..."
        } else if activities.isEmpty {
            return "Sync Activities"
        } else {
            return "Sync Again"
        }
    }
    
    /// Check if token needs refresh
    var needsTokenRefresh: Bool {
        return connection?.needsRefresh ?? false
    }
}

