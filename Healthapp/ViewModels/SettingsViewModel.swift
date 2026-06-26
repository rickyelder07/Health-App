//
//  SettingsViewModel.swift
//  Netfuel
//
//  ViewModel for settings and preferences
//

import Foundation
import Combine
import Supabase

/// ViewModel for settings view
@MainActor
class SettingsViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var settings: UserSettings
    @Published var user: User?
    @Published var stravaConnection: StravaConnection?
    @Published var lastStravaSync: Date?

    @Published var isLoading = false
    @Published var isSaving = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    // MARK: - Private Properties

    private let userId: UUID
    private let profileService = ProfileService.shared
    private let stravaService = StravaService()
    private let authService = AuthenticationService()

    // MARK: - Initialization

    init(userId: UUID) {
        self.userId = userId
        self.settings = UserSettings.load()
    }

    // MARK: - Data Loading

    /// Load user profile and settings
    func loadData() async {
        isLoading = true
        errorMessage = nil

        do {
            // Load user profile
            user = try await profileService.fetchProfile(userId: userId)

            // Load Strava connection
            stravaConnection = try? await stravaService.fetchConnection(userId: userId)

            // Get last sync time from activities
            if stravaConnection != nil {
                let activities = try await stravaService.fetchActivitiesFromDatabase(
                    userId: userId,
                    startDate: Date().addingTimeInterval(-30 * 24 * 60 * 60),
                    endDate: Date()
                )
                lastStravaSync = activities.first?.createdAt
            }

        } catch {
            errorMessage = "Failed to load settings: \(error.localizedDescription)"
        }

        isLoading = false
    }

    // MARK: - Settings Management

    /// Save settings to UserDefaults
    func saveSettings() {
        settings.save()
        successMessage = "Settings saved"

        // Clear success message after 2 seconds
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            successMessage = nil
        }
    }

    /// Update user profile in database
    func updateProfile(weight: Double? = nil, height: Double? = nil, age: Int? = nil, gender: Gender? = nil, activityLevel: ActivityLevel? = nil) async {
        guard var currentUser = user else { return }

        isSaving = true
        errorMessage = nil

        do {
            // Update profile with individual fields
            let updatedUser = try await profileService.updateProfile(
                userId: userId,
                weight: weight,
                height: height,
                age: age,
                gender: gender,
                activityLevel: activityLevel
            )
            user = updatedUser
            successMessage = "Profile updated"

            // Clear success message after 2 seconds
            Task {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                successMessage = nil
            }
        } catch {
            errorMessage = "Failed to update profile: \(error.localizedDescription)"
        }

        isSaving = false
    }

    // MARK: - Strava Integration

    /// Disconnect from Strava
    func disconnectStrava() async {
        guard stravaConnection != nil else { return }

        do {
            try await stravaService.disconnect(userId: userId)
            stravaConnection = nil
            successMessage = "Strava disconnected"
        } catch {
            errorMessage = "Failed to disconnect Strava: \(error.localizedDescription)"
        }
    }

    /// Manually sync Strava activities
    func syncStravaActivities() async {
        guard let connection = stravaConnection else {
            errorMessage = "Strava not connected"
            return
        }

        isSaving = true
        errorMessage = nil

        do {
            try await stravaService.syncActivities(userId: userId, connection: connection)
            lastStravaSync = Date()
            successMessage = "Strava synced"

            // Clear success message after 2 seconds
            Task {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                successMessage = nil
            }
        } catch {
            errorMessage = "Failed to sync Strava: \(error.localizedDescription)"
        }

        isSaving = false
    }

    // MARK: - Account Actions

    /// Change password
    func changePassword(newPassword: String) async {
        isSaving = true
        errorMessage = nil

        do {
            try await authService.updatePassword(newPassword: newPassword)
            successMessage = "Password updated"

            // Clear success message after 2 seconds
            Task {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                successMessage = nil
            }
        } catch {
            errorMessage = "Failed to change password: \(error.localizedDescription)"
        }

        isSaving = false
    }

    /// Export all user data
    func exportData() -> String {
        var csv = "Netfuel Data Export\n\n"

        // User profile
        if let user = user {
            csv += "PROFILE\n"
            csv += "Email,\(user.email ?? "N/A")\n"
            csv += "Weight,\(user.weight ?? 0) kg\n"
            csv += "Height,\(user.height ?? 0) cm\n"
            csv += "Age,\(user.age ?? 0)\n"
            csv += "Gender,\(user.gender?.rawValue ?? "N/A")\n"
            csv += "Activity Level,\(user.activityLevel?.rawValue ?? "N/A")\n"
            csv += "BMR,\(user.bmr ?? 0) cal\n"
            csv += "TDEE,\(user.tdee ?? 0) cal\n\n"
        }

        // Settings
        csv += "SETTINGS\n"
        csv += "Daily Calorie Target,\(settings.dailyCalorieTarget ?? 0)\n"
        csv += "Protein Target,\(settings.proteinTargetGrams ?? 0) g\n"
        csv += "Carbs Target,\(settings.carbsTargetGrams ?? 0) g\n"
        csv += "Fat Target,\(settings.fatTargetGrams ?? 0) g\n"
        csv += "Weight Goal,\(settings.weightGoal ?? 0) kg\n"
        csv += "Weight Unit,\(settings.weightUnit.rawValue)\n"
        csv += "Height Unit,\(settings.heightUnit.rawValue)\n"
        csv += "Distance Unit,\(settings.distanceUnit.rawValue)\n\n"

        // Strava
        if let connection = stravaConnection {
            csv += "STRAVA\n"
            csv += "Connected,Yes\n"
            csv += "Athlete,\(connection.athleteFullName)\n"
            csv += "Connected At,\(connection.connectedAt.displayString)\n\n"
        }

        return csv
    }

    /// Delete user account
    func deleteAccount() async throws {
        isSaving = true
        errorMessage = nil

        do {
            // Delete all user data from Supabase
            try await profileService.deleteUserAccount(userId: userId)

            // Sign out
            try await authService.signOut()

        } catch {
            errorMessage = "Failed to delete account: \(error.localizedDescription)"
            isSaving = false
            throw error
        }
    }

    /// Log out
    func logOut() async {
        do {
            try await authService.signOut()
        } catch {
            errorMessage = "Failed to log out: \(error.localizedDescription)"
        }
    }

    // MARK: - Computed Properties

    /// App version string
    var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    /// Formatted last sync time
    var formattedLastSync: String {
        guard let lastSync = lastStravaSync else { return "Never" }

        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: lastSync, relativeTo: Date())
    }

    /// Calculated BMR
    var calculatedBMR: Int {
        Int(user?.bmr ?? user?.calculateBMR() ?? 0)
    }

    /// Calculated TDEE
    var calculatedTDEE: Int {
        Int(user?.tdee ?? user?.calculateTDEE() ?? 0)
    }

    /// Effective calorie target based on fitness goal
    var effectiveCalorieTarget: Int {
        settings.effectiveCalorieTarget(tdee: calculatedTDEE)
    }
}
