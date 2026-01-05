//
//  NotificationManager.swift
//  Netfuel
//
//  Manages local notifications for reminders and updates
//

import Foundation
import UserNotifications
import UIKit

/// Manages local notifications for the app
class NotificationManager {

    // MARK: - Singleton

    static let shared = NotificationManager()

    // MARK: - Properties

    private let center = UNUserNotificationCenter.current()

    /// User preferences for notifications
    var preferences: NotificationPreferences {
        get { NotificationPreferences.load() }
        set { newValue.save() }
    }

    // MARK: - Notification Identifiers

    private enum Identifier {
        static let dailyLoggingReminder = "com.netfuel.reminder.daily_logging"
        static let stravaSync = "com.netfuel.reminder.strava_sync"
        static let weeklyProgress = "com.netfuel.summary.weekly_progress"
    }

    // MARK: - Initialization

    private init() {
        // Configure notification categories
        configureCategoryActions()
    }

    // MARK: - Permission Management

    /// Request notification permissions
    func requestPermissions() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])

            if granted {
                print("✅ Notification permissions granted")
            } else {
                print("❌ Notification permissions denied")
            }

            return granted
        } catch {
            print("❌ Failed to request notification permissions: \(error)")
            return false
        }
    }

    /// Check current notification authorization status
    func checkPermissionStatus() async -> UNAuthorizationStatus {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus
    }

    /// Check if notifications are authorized
    func areNotificationsAuthorized() async -> Bool {
        let status = await checkPermissionStatus()
        return status == .authorized || status == .provisional
    }

    // MARK: - Daily Logging Reminder

    /// Schedule daily logging reminder
    /// - Parameter time: Time to send reminder (e.g., 8:00 PM)
    func scheduleDailyLoggingReminder(at time: Date) {
        guard preferences.dailyLoggingReminderEnabled else {
            cancelDailyLoggingReminder()
            return
        }

        // Remove existing reminder
        center.removePendingNotificationRequests(withIdentifiers: [Identifier.dailyLoggingReminder])

        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Log Your Meals"
        content.body = "Don't forget to track your food intake for today!"
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "DAILY_LOGGING"
        content.userInfo = ["type": "daily_logging"]

        // Create trigger
        let components = Calendar.current.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        // Create request
        let request = UNNotificationRequest(
            identifier: Identifier.dailyLoggingReminder,
            content: content,
            trigger: trigger
        )

        // Schedule notification
        center.add(request) { error in
            if let error = error {
                print("❌ Failed to schedule daily logging reminder: \(error)")
            } else {
                print("✅ Daily logging reminder scheduled for \(components.hour!):\(String(format: "%02d", components.minute!))")
            }
        }
    }

    /// Cancel daily logging reminder
    func cancelDailyLoggingReminder() {
        center.removePendingNotificationRequests(withIdentifiers: [Identifier.dailyLoggingReminder])
        print("🔕 Daily logging reminder canceled")
    }

    // MARK: - Strava Sync Reminder

    /// Schedule Strava sync reminder
    /// - Parameter daysInterval: Number of days between reminders (default: 3)
    func scheduleStravaSyncReminder(daysInterval: Int = 3) {
        guard preferences.stravaSyncReminderEnabled else {
            cancelStravaSyncReminder()
            return
        }

        // Remove existing reminder
        center.removePendingNotificationRequests(withIdentifiers: [Identifier.stravaSync])

        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Sync Your Workouts"
        content.body = "Sync your Strava activities to track exercise calories."
        content.sound = .default
        content.categoryIdentifier = "STRAVA_SYNC"
        content.userInfo = ["type": "strava_sync"]

        // Create trigger (repeat every X days at 6 PM)
        var components = DateComponents()
        components.hour = 18  // 6 PM
        components.minute = 0

        // Schedule for the next occurrence
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        // Create request
        let request = UNNotificationRequest(
            identifier: Identifier.stravaSync,
            content: content,
            trigger: trigger
        )

        // Schedule notification
        center.add(request) { error in
            if let error = error {
                print("❌ Failed to schedule Strava sync reminder: \(error)")
            } else {
                print("✅ Strava sync reminder scheduled")
            }
        }
    }

    /// Cancel Strava sync reminder
    func cancelStravaSyncReminder() {
        center.removePendingNotificationRequests(withIdentifiers: [Identifier.stravaSync])
        print("🔕 Strava sync reminder canceled")
    }

    // MARK: - Weekly Progress Summary

    /// Schedule weekly progress summary notification
    /// - Parameters:
    ///   - weekday: Day of week (1 = Sunday, 7 = Saturday)
    ///   - hour: Hour of day (0-23)
    func scheduleWeeklyProgressSummary(weekday: Int = 1, hour: Int = 9) {
        guard preferences.weeklyProgressSummaryEnabled else {
            cancelWeeklyProgressSummary()
            return
        }

        // Remove existing summary
        center.removePendingNotificationRequests(withIdentifiers: [Identifier.weeklyProgress])

        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Weekly Progress Summary"
        content.body = "Check out your progress from this week!"
        content.sound = .default
        content.categoryIdentifier = "WEEKLY_SUMMARY"
        content.userInfo = ["type": "weekly_progress"]

        // Create trigger (every Sunday at 9 AM by default)
        var components = DateComponents()
        components.weekday = weekday  // 1 = Sunday
        components.hour = hour
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        // Create request
        let request = UNNotificationRequest(
            identifier: Identifier.weeklyProgress,
            content: content,
            trigger: trigger
        )

        // Schedule notification
        center.add(request) { error in
            if let error = error {
                print("❌ Failed to schedule weekly progress summary: \(error)")
            } else {
                let dayName = Calendar.current.weekdaySymbols[weekday - 1]
                print("✅ Weekly progress summary scheduled for \(dayName) at \(hour):00")
            }
        }
    }

    /// Cancel weekly progress summary
    func cancelWeeklyProgressSummary() {
        center.removePendingNotificationRequests(withIdentifiers: [Identifier.weeklyProgress])
        print("🔕 Weekly progress summary canceled")
    }

    // MARK: - Instant Notifications

    /// Send immediate notification (for testing or one-time events)
    func sendInstantNotification(title: String, body: String, userInfo: [String: Any] = [:]) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = userInfo

        // Trigger immediately
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error = error {
                print("❌ Failed to send instant notification: \(error)")
            } else {
                print("✅ Instant notification sent: \(title)")
            }
        }
    }

    // MARK: - Notification Actions

    /// Configure notification category actions
    private func configureCategoryActions() {
        // Daily Logging category
        let logNowAction = UNNotificationAction(
            identifier: "LOG_NOW",
            title: "Log Now",
            options: [.foreground]
        )

        let logLaterAction = UNNotificationAction(
            identifier: "LOG_LATER",
            title: "Remind Me Later",
            options: []
        )

        let dailyLoggingCategory = UNNotificationCategory(
            identifier: "DAILY_LOGGING",
            actions: [logNowAction, logLaterAction],
            intentIdentifiers: [],
            options: []
        )

        // Strava Sync category
        let syncNowAction = UNNotificationAction(
            identifier: "SYNC_NOW",
            title: "Sync Now",
            options: [.foreground]
        )

        let stravaSyncCategory = UNNotificationCategory(
            identifier: "STRAVA_SYNC",
            actions: [syncNowAction],
            intentIdentifiers: [],
            options: []
        )

        // Weekly Summary category
        let viewSummaryAction = UNNotificationAction(
            identifier: "VIEW_SUMMARY",
            title: "View Summary",
            options: [.foreground]
        )

        let weeklySummaryCategory = UNNotificationCategory(
            identifier: "WEEKLY_SUMMARY",
            actions: [viewSummaryAction],
            intentIdentifiers: [],
            options: []
        )

        // Register categories
        center.setNotificationCategories([
            dailyLoggingCategory,
            stravaSyncCategory,
            weeklySummaryCategory
        ])
    }

    // MARK: - Utility Methods

    /// Get all pending notifications
    func getPendingNotifications() async -> [UNNotificationRequest] {
        return await center.pendingNotificationRequests()
    }

    /// Get delivered notifications
    func getDeliveredNotifications() async -> [UNNotification] {
        return await center.deliveredNotifications()
    }

    /// Clear all delivered notifications
    func clearDeliveredNotifications() {
        center.removeAllDeliveredNotifications()
        UIApplication.shared.applicationIconBadgeNumber = 0
    }

    /// Cancel all pending notifications
    func cancelAllNotifications() {
        center.removeAllPendingNotificationRequests()
        print("🔕 All notifications canceled")
    }

    /// Reschedule all active notifications based on current preferences
    func rescheduleAllNotifications() {
        if preferences.dailyLoggingReminderEnabled {
            scheduleDailyLoggingReminder(at: preferences.dailyLoggingTime)
        }

        if preferences.stravaSyncReminderEnabled {
            scheduleStravaSyncReminder(daysInterval: 3)
        }

        if preferences.weeklyProgressSummaryEnabled {
            scheduleWeeklyProgressSummary(weekday: preferences.weeklyProgressDay, hour: preferences.weeklyProgressHour)
        }
    }

    // MARK: - Debug & Testing Methods

    #if DEBUG

    /// Send an immediate test notification
    func sendTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Test Notification"
        content.body = "This is a test notification from the debug menu"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "com.netfuel.test.\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error = error {
                Logger.error("Failed to send test notification: \(error.localizedDescription)", category: .general)
            }
        }
    }

    /// Send an immediate notification with custom content
    func sendImmediateNotification(title: String, body: String, identifier: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error = error {
                Logger.error("Failed to send immediate notification: \(error.localizedDescription)", category: .general)
            }
        }
    }

    #endif
}

// MARK: - Notification Preferences Model

/// User preferences for notifications
struct NotificationPreferences: Codable {

    // Daily Logging Reminder
    var dailyLoggingReminderEnabled: Bool = false
    var dailyLoggingTime: Date = {
        var components = DateComponents()
        components.hour = 20  // 8 PM default
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }()

    // Strava Sync Reminder
    var stravaSyncReminderEnabled: Bool = false

    // Weekly Progress Summary
    var weeklyProgressSummaryEnabled: Bool = false
    var weeklyProgressDay: Int = 1  // Sunday
    var weeklyProgressHour: Int = 9  // 9 AM

    // MARK: - UserDefaults Storage

    private static let key = "com.netfuel.notificationPreferences"

    /// Load preferences from UserDefaults
    static func load() -> NotificationPreferences {
        guard let data = UserDefaults.standard.data(forKey: key),
              let prefs = try? JSONDecoder().decode(NotificationPreferences.self, from: data) else {
            return NotificationPreferences()  // Return default preferences
        }
        return prefs
    }

    /// Save preferences to UserDefaults
    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: NotificationPreferences.key)
        }
    }

    /// Clear all preferences
    static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
