//
//  TestScenarios.swift
//  Netfuel
//
//  Utilities for setting up different test scenarios and user states
//

import Foundation
import UserNotifications

#if DEBUG

/// Test scenarios for different user states and testing conditions
class TestScenarios {

    static let shared = TestScenarios()

    private init() {}

    // MARK: - User State Scenarios

    /// Configure app for first-time user experience
    func setupFirstTimeUser() {
        // Clear all data
        clearAllData()

        // Set onboarding as incomplete
        UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
        UserDefaults.standard.set(false, forKey: "hasCompletedProfileSetup")

        // Clear any cached session
        // Would need to clear Supabase session here

        Logger.info("Test scenario: First-time user configured", category: .general)
    }

    /// Configure app for returning user with complete profile
    func setupReturningUser() {
        // Clear data but keep settings
        clearDataExceptSettings()

        // Mark onboarding as complete
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        UserDefaults.standard.set(true, forKey: "hasCompletedProfileSetup")

        // Set up user settings
        var settings = UserSettings()
        settings.calorieGoalSource = .tdee
        settings.proteinTargetGrams = 150.0
        settings.carbsTargetGrams = 250.0
        settings.fatTargetGrams = 70.0
        settings.weightGoal = 72.0
        settings.save()

        Logger.info("Test scenario: Returning user configured", category: .general)
    }

    /// Configure app for user without Strava connection
    func setupUserWithoutStrava() {
        setupReturningUser()

        // Clear Strava-related data
        // Would need to clear strava_connections from database

        // Clear any cached Strava tokens
        UserDefaults.standard.removeObject(forKey: "stravaAccessToken")
        UserDefaults.standard.removeObject(forKey: "stravaRefreshToken")

        Logger.info("Test scenario: User without Strava configured", category: .strava)
    }

    /// Configure app for user with no activities today
    func setupUserWithNoActivitiesToday() {
        setupReturningUser()

        // Would need to clear today's activities from database
        // This would be done via service methods in a real implementation

        Logger.info("Test scenario: User with no activities today", category: .general)
    }

    /// Configure app for offline mode simulation
    func setupOfflineMode() {
        // Enable offline mode flag
        UserDefaults.standard.set(true, forKey: "simulateOfflineMode")

        // This flag would be checked by networking layer to fail all requests

        Logger.info("Test scenario: Offline mode configured", category: .network)
    }

    /// Configure app with sample data
    func setupUserWithSampleData() {
        setupReturningUser()

        // This would populate database with sample data
        // In real implementation, would use services to insert data

        Logger.info("Test scenario: User with sample data configured", category: .general)
    }

    // MARK: - Network Scenarios

    /// Simulate slow network conditions
    func setupSlowNetwork(delaySeconds: Double = 3.0) {
        UserDefaults.standard.set(true, forKey: "simulateSlowNetwork")
        UserDefaults.standard.set(delaySeconds, forKey: "networkDelaySeconds")

        Logger.info("Test scenario: Slow network (\(delaySeconds)s delay) configured", category: .network)
    }

    /// Simulate network failures
    func setupNetworkFailures() {
        UserDefaults.standard.set(true, forKey: "simulateNetworkFailures")

        Logger.info("Test scenario: Network failures configured", category: .network)
    }

    /// Reset network simulation
    func resetNetworkSimulation() {
        UserDefaults.standard.removeObject(forKey: "simulateOfflineMode")
        UserDefaults.standard.removeObject(forKey: "simulateSlowNetwork")
        UserDefaults.standard.removeObject(forKey: "simulateNetworkFailures")
        UserDefaults.standard.removeObject(forKey: "networkDelaySeconds")

        Logger.info("Test scenario: Network simulation reset", category: .network)
    }

    // MARK: - Data Population

    /// Populate with sample food logs
    func populateSampleFoodLogs(userId: UUID, count: Int = 5) {
        let sampleLogs = PreviewData.generateFoodLogs(count: count, for: userId)

        // Would insert via FoodService
        Logger.info("Test scenario: \(count) sample food logs created", category: .general)
    }

    /// Populate with sample activities
    func populateSampleActivities(userId: UUID, count: Int = 3) {
        let sampleActivities = PreviewData.generateActivities(count: count, for: userId)

        // Would insert via StravaService
        Logger.info("Test scenario: \(count) sample activities created", category: .strava)
    }

    /// Populate with sample daily summaries
    func populateSampleDailySummaries(userId: UUID, days: Int = 7) {
        let summaries = PreviewData.generateDailySummaries(days: days, for: userId)

        // Would insert via DailySummaryService
        Logger.info("Test scenario: \(days) daily summaries created", category: .general)
    }

    // MARK: - Data Clearing

    /// Clear all app data
    func clearAllData() {
        // Clear UserDefaults
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }

        // Clear settings
        UserSettings.clear()

        // Clear notification preferences
        NotificationPreferences.clear()

        // Clear image cache
        ImageCache.shared.clearAll()

        // Clear offline queue
        OfflineStorageManager.shared.clearQueue()

        // Clear debug logs
        DebugLogger.shared.clearLogs()

        Logger.info("Test scenario: All data cleared", category: .general)
    }

    /// Clear data but preserve settings
    func clearDataExceptSettings() {
        // Clear image cache
        ImageCache.shared.clearAll()

        // Clear offline queue
        OfflineStorageManager.shared.clearQueue()

        // Clear specific UserDefaults keys but keep settings
        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
        UserDefaults.standard.removeObject(forKey: "lastSyncDate")

        Logger.info("Test scenario: Data cleared (settings preserved)", category: .general)
    }

    // MARK: - Error Scenarios

    /// Simulate authentication error
    func simulateAuthenticationError() {
        UserDefaults.standard.set(true, forKey: "simulateAuthError")

        Logger.info("Test scenario: Authentication error configured", category: .auth)
    }

    /// Simulate database error
    func simulateDatabaseError() {
        UserDefaults.standard.set(true, forKey: "simulateDatabaseError")

        Logger.info("Test scenario: Database error configured", category: .database)
    }

    /// Reset error simulations
    func resetErrorSimulations() {
        UserDefaults.standard.removeObject(forKey: "simulateAuthError")
        UserDefaults.standard.removeObject(forKey: "simulateDatabaseError")

        Logger.info("Test scenario: Error simulations reset", category: .general)
    }

    // MARK: - Notification Scenarios

    /// Schedule immediate test notification
    func scheduleTestNotification() {
        NotificationManager.shared.sendTestNotification()

        Logger.info("Test scenario: Test notification scheduled", category: .general)
    }

    /// Clear all pending notifications
    func clearAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()

        Logger.info("Test scenario: All notifications cleared", category: .general)
    }

    // MARK: - Helper Methods

    /// Check if running in test mode
    var isTestMode: Bool {
        ProcessInfo.processInfo.arguments.contains("--uitesting")
    }

    /// Check if offline mode is simulated
    var isOfflineModeSimulated: Bool {
        UserDefaults.standard.bool(forKey: "simulateOfflineMode")
    }

    /// Check if slow network is simulated
    var isSlowNetworkSimulated: Bool {
        UserDefaults.standard.bool(forKey: "simulateSlowNetwork")
    }

    /// Get network delay duration
    var networkDelayDuration: Double {
        UserDefaults.standard.double(forKey: "networkDelaySeconds")
    }

    // MARK: - UI Testing Support

    /// Configure app based on launch arguments
    func configureFromLaunchArguments() {
        let args = ProcessInfo.processInfo.arguments

        if args.contains("--uitesting") {
            Logger.info("Running in UI testing mode", category: .general)
        }

        if args.contains("--new-user") {
            setupFirstTimeUser()
        }

        if args.contains("--authenticated") {
            setupReturningUser()
        }

        if args.contains("--offline") {
            setupOfflineMode()
        }

        if args.contains("--slow-network") {
            setupSlowNetwork()
        }

        if args.contains("--with-sample-data") {
            setupUserWithSampleData()
        }

        // Check environment variables
        let env = ProcessInfo.processInfo.environment

        if env["RESET_APP_STATE"] == "true" {
            clearAllData()
        }

        if let userId = env["TEST_USER_ID"] {
            Logger.info("Using test user ID: \(userId)", category: .general)
        }
    }
}

// MARK: - Network Simulation Helper

/// Helper for simulating network conditions in tests
class NetworkSimulator {

    static let shared = NetworkSimulator()

    private init() {}

    /// Check if should fail network request
    var shouldFailRequest: Bool {
        UserDefaults.standard.bool(forKey: "simulateNetworkFailures")
    }

    /// Check if should delay network request
    var shouldDelayRequest: Bool {
        UserDefaults.standard.bool(forKey: "simulateSlowNetwork")
    }

    /// Get delay duration for network request
    var delayDuration: TimeInterval {
        UserDefaults.standard.double(forKey: "networkDelaySeconds")
    }

    /// Simulate network delay
    func simulateDelay() async {
        guard shouldDelayRequest else { return }

        let delay = delayDuration > 0 ? delayDuration : 2.0
        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
    }

    /// Get simulated error if should fail
    func getSimulatedError() -> Error? {
        guard shouldFailRequest else { return nil }

        return NSError(
            domain: "NetworkSimulator",
            code: 500,
            userInfo: [NSLocalizedDescriptionKey: "Simulated network failure"]
        )
    }
}

#endif
