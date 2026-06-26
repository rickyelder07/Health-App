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

        // Meal Reminder category
        let logMealAction = UNNotificationAction(
            identifier: "LOG_MEAL",
            title: "Log Now",
            options: [.foreground]
        )
        let mealReminderCategory = UNNotificationCategory(
            identifier: "MEAL_REMINDER",
            actions: [logMealAction],
            intentIdentifiers: [],
            options: []
        )

        // Register categories
        center.setNotificationCategories([
            dailyLoggingCategory,
            stravaSyncCategory,
            weeklySummaryCategory,
            mealReminderCategory
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

    // MARK: - Meal Reminders

    /// Schedule smart meal reminders for the next 7 days.
    /// Each notification has a per-day identifier so individual days can be cancelled when food is logged.
    func scheduleMealReminders() {
        cancelAllMealReminders()
        let prefs = preferences
        let now = Date()
        let cal = Calendar.current

        let meals: [(MealType, Bool, Date)] = [
            (.breakfast, prefs.breakfastReminderEnabled, prefs.breakfastTime),
            (.lunch,     prefs.lunchReminderEnabled,     prefs.lunchTime),
            (.dinner,    prefs.dinnerReminderEnabled,    prefs.dinnerTime),
        ]

        for dayOffset in 0..<7 {
            guard let day = cal.date(byAdding: .day, value: dayOffset, to: now) else { continue }
            for (meal, enabled, mealTime) in meals {
                guard enabled else { continue }
                let hour = cal.component(.hour, from: mealTime)
                let minute = cal.component(.minute, from: mealTime)
                guard let fireDate = cal.date(bySettingHour: hour, minute: minute, second: 0, of: day),
                      fireDate > now else { continue }

                let content = UNMutableNotificationContent()
                let (title, body) = mealPromptMessage(for: meal, date: day)
                content.title = title
                content.body = body
                content.sound = .default
                content.categoryIdentifier = "MEAL_REMINDER"
                content.userInfo = ["type": "meal_reminder", "meal": meal.rawValue]

                let components = cal.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                let request = UNNotificationRequest(
                    identifier: mealNotificationId(meal, date: day),
                    content: content,
                    trigger: trigger
                )
                center.add(request) { error in
                    if let error = error {
                        print("❌ Failed to schedule \(meal.rawValue) reminder: \(error)")
                    }
                }
            }
        }
        print("✅ Meal reminders scheduled for next 7 days")
    }

    /// Cancel the meal reminder for a specific meal on a specific date (call after food is logged).
    func cancelMealNotification(meal: MealType, date: Date) {
        center.removePendingNotificationRequests(withIdentifiers: [mealNotificationId(meal, date: date)])
    }

    /// Cancel all pending meal reminders.
    func cancelAllMealReminders() {
        let cal = Calendar.current
        let now = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"

        var ids: [String] = []
        for dayOffset in 0..<14 {
            guard let day = cal.date(byAdding: .day, value: dayOffset, to: now) else { continue }
            let key = formatter.string(from: day)
            for meal in [MealType.breakfast, .lunch, .dinner] {
                ids.append("netfuel.meal.\(meal.rawValue).\(key)")
            }
        }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    private func mealNotificationId(_ meal: MealType, date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        let key = formatter.string(from: Calendar.current.startOfDay(for: date))
        return "netfuel.meal.\(meal.rawValue).\(key)"
    }

    private func mealPromptMessage(for meal: MealType, date: Date) -> (String, String) {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 0
        let messages: [MealType: [(String, String)]] = [
            .breakfast: [
                ("Have you logged breakfast? 🌅", "Starting your day with tracking sets you up for success!"),
                ("Breakfast check-in!", "Don't forget to log your morning meal — every bite counts toward your goals."),
                ("Good morning! ☀️", "Have you eaten breakfast? Log it now to stay on track 💪"),
            ],
            .lunch: [
                ("Time to log lunch! 🥗", "Have you eaten lunch? Logging keeps you honest with your goals."),
                ("Lunch check-in!", "Don't let midday slip by — log what you ate to stay on target."),
                ("Halfway through the day!", "Have you logged lunch yet? Consistent tracking = consistent results 🎯"),
            ],
            .dinner: [
                ("Dinner time! 🍽️", "Have you logged your dinner? Finish the day strong!"),
                ("Evening check-in!", "Don't forget dinner — logging every meal helps you hit your goals."),
                ("Almost done for the day! 🌟", "Have you logged dinner? You're so close to a fully tracked day."),
            ],
        ]
        let options = messages[meal] ?? [("Log your meal!", "Don't forget to track what you ate.")]
        return options[dayOfYear % options.count]
    }

    /// Reschedule all active notifications based on current preferences
    func rescheduleAllNotifications() {
        scheduleMealReminders()

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

    // Meal Reminders
    var breakfastReminderEnabled: Bool = true
    var breakfastTime: Date = {
        var c = DateComponents(); c.hour = 9; c.minute = 0
        return Calendar.current.date(from: c) ?? Date()
    }()
    var lunchReminderEnabled: Bool = true
    var lunchTime: Date = {
        var c = DateComponents(); c.hour = 13; c.minute = 0
        return Calendar.current.date(from: c) ?? Date()
    }()
    var dinnerReminderEnabled: Bool = true
    var dinnerTime: Date = {
        var c = DateComponents(); c.hour = 19; c.minute = 30
        return Calendar.current.date(from: c) ?? Date()
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
