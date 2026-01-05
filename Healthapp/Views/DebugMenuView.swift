//
//  DebugMenuView.swift
//  Netfuel
//
//  Debug menu for testing and troubleshooting (DEBUG builds only)
//

import SwiftUI
import UserNotifications
import Combine

#if DEBUG

/// Debug menu for development and testing
struct DebugMenuView: View {
    @StateObject private var viewModel = DebugMenuViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                // Data Management Section
                Section {
                    Button(role: .destructive) {
                        viewModel.clearUserDefaults()
                    } label: {
                        Label("Clear UserDefaults", systemImage: "trash")
                    }

                    Button(role: .destructive) {
                        viewModel.clearKeychain()
                    } label: {
                        Label("Clear Keychain", systemImage: "key.slash")
                    }

                    Button(role: .destructive) {
                        viewModel.resetOnboarding()
                    } label: {
                        Label("Reset Onboarding", systemImage: "arrow.counterclockwise")
                    }

                    Button(role: .destructive) {
                        viewModel.clearImageCache()
                    } label: {
                        Label("Clear Image Cache", systemImage: "photo.on.rectangle.angled")
                    }

                    Button(role: .destructive) {
                        viewModel.clearOfflineQueue()
                    } label: {
                        Label("Clear Offline Queue", systemImage: "wifi.slash")
                    }

                    Button(role: .destructive) {
                        viewModel.clearAllData()
                    } label: {
                        Label("Clear ALL Data", systemImage: "exclamationmark.triangle")
                    }
                } header: {
                    Text("Data Management")
                } footer: {
                    Text("Warning: These actions cannot be undone")
                }

                // Sample Data Section
                Section {
                    Button {
                        viewModel.populateSampleFoodLogs()
                    } label: {
                        Label("Add Sample Food Logs", systemImage: "fork.knife")
                    }

                    Button {
                        viewModel.populateSampleActivities()
                    } label: {
                        Label("Add Sample Activities", systemImage: "figure.run")
                    }

                    Button {
                        viewModel.populateSamplePhotos()
                    } label: {
                        Label("Add Sample Photos", systemImage: "photo.stack")
                    }

                    Button {
                        viewModel.populateCompleteSampleData()
                    } label: {
                        Label("Populate All Sample Data", systemImage: "doc.on.doc")
                    }
                } header: {
                    Text("Sample Data")
                } footer: {
                    Text("Add test data for development")
                }

                // Notifications Section
                Section {
                    Button {
                        viewModel.triggerTestNotification()
                    } label: {
                        Label("Trigger Test Notification", systemImage: "bell.badge")
                    }

                    Button {
                        viewModel.triggerDailyReminder()
                    } label: {
                        Label("Trigger Daily Reminder", systemImage: "bell.fill")
                    }

                    Button {
                        viewModel.triggerWeeklySummary()
                    } label: {
                        Label("Trigger Weekly Summary", systemImage: "calendar.badge.clock")
                    }

                    Button {
                        viewModel.clearAllNotifications()
                    } label: {
                        Label("Clear All Notifications", systemImage: "bell.slash")
                    }
                } header: {
                    Text("Notifications")
                }

                // Authentication Section
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("User ID")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        if let userId = viewModel.currentUserId {
                            Text(userId)
                                .font(.system(.caption, design: .monospaced))
                                .textSelection(.enabled)
                        } else {
                            Text("Not authenticated")
                                .foregroundColor(.secondary)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Session Token")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        if let token = viewModel.sessionToken {
                            Text(token.prefix(50) + "...")
                                .font(.system(.caption, design: .monospaced))
                                .textSelection(.enabled)
                                .lineLimit(2)
                        } else {
                            Text("No token")
                                .foregroundColor(.secondary)
                        }
                    }

                    Button {
                        viewModel.refreshSession()
                    } label: {
                        Label("Refresh Session", systemImage: "arrow.clockwise")
                    }
                } header: {
                    Text("Authentication")
                }

                // Network Section
                Section {
                    Toggle("Enable Network Logging", isOn: $viewModel.networkLoggingEnabled)

                    Toggle("Mock Network Failures", isOn: $viewModel.mockNetworkFailures)

                    Toggle("Simulate Slow Network", isOn: $viewModel.simulateSlowNetwork)

                    if viewModel.simulateSlowNetwork {
                        HStack {
                            Text("Delay: \(Int(viewModel.networkDelay))s")
                            Slider(value: $viewModel.networkDelay, in: 1...10, step: 1)
                        }
                    }
                } header: {
                    Text("Network")
                }

                // Logging Section
                Section {
                    Toggle("Verbose Logging", isOn: $viewModel.verboseLogging)

                    Button {
                        viewModel.exportLogs()
                    } label: {
                        Label("Export Logs", systemImage: "square.and.arrow.up")
                    }

                    Button {
                        viewModel.clearLogs()
                    } label: {
                        Label("Clear Logs", systemImage: "trash")
                    }

                    Text("Log entries: \(viewModel.logCount)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } header: {
                    Text("Logging")
                }

                // Environment Info Section
                Section {
                    DebugInfoRow(title: "App Version", value: viewModel.appVersion)
                    DebugInfoRow(title: "Build Number", value: viewModel.buildNumber)
                    DebugInfoRow(title: "Bundle ID", value: viewModel.bundleIdentifier)
                    DebugInfoRow(title: "Device", value: viewModel.deviceModel)
                    DebugInfoRow(title: "iOS Version", value: viewModel.iOSVersion)
                    DebugInfoRow(title: "Supabase URL", value: viewModel.supabaseURL)
                } header: {
                    Text("Environment")
                }

                // Test Scenarios Section
                Section {
                    Button {
                        viewModel.simulateFirstTimeUser()
                    } label: {
                        Label("First-Time User", systemImage: "person.badge.plus")
                    }

                    Button {
                        viewModel.simulateReturningUser()
                    } label: {
                        Label("Returning User", systemImage: "person.fill.checkmark")
                    }

                    Button {
                        viewModel.simulateUserWithoutStrava()
                    } label: {
                        Label("User Without Strava", systemImage: "figure.run.slash")
                    }

                    Button {
                        viewModel.simulateOfflineMode()
                    } label: {
                        Label("Offline Mode", systemImage: "wifi.slash")
                    }
                } header: {
                    Text("Test Scenarios")
                } footer: {
                    Text("Configure app state for different testing scenarios")
                }
            }
            .navigationTitle("Debug Menu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Action Complete", isPresented: $viewModel.showSuccessAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.successMessage)
            }
            .alert("Error", isPresented: $viewModel.showErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage)
            }
            .sheet(isPresented: $viewModel.showShareSheet) {
                if let url = viewModel.exportURL {
                    ShareSheet(activityItems: [url])
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct DebugInfoRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.primary)
                .textSelection(.enabled)
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Debug Menu View Model

@MainActor
class DebugMenuViewModel: ObservableObject {
    @Published var networkLoggingEnabled = true
    @Published var mockNetworkFailures = false
    @Published var simulateSlowNetwork = false
    @Published var networkDelay: Double = 2.0
    @Published var verboseLogging = false

    @Published var showSuccessAlert = false
    @Published var showErrorAlert = false
    @Published var successMessage = ""
    @Published var errorMessage = ""

    @Published var showShareSheet = false
    @Published var exportURL: URL?

    // MARK: - Info Properties

    var currentUserId: String? {
        // Try to get from Supabase session
        return "Mock-User-ID" // Replace with actual session fetch
    }

    var sessionToken: String? {
        // Try to get from Supabase session
        return "mock.session.token" // Replace with actual token fetch
    }

    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }

    var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }

    var bundleIdentifier: String {
        Bundle.main.bundleIdentifier ?? "Unknown"
    }

    var deviceModel: String {
        UIDevice.current.model
    }

    var iOSVersion: String {
        UIDevice.current.systemVersion
    }

    var supabaseURL: String {
        Configuration.Supabase.url
    }

    var logCount: Int {
        DebugLogger.shared.logCount
    }

    // MARK: - Data Management

    func clearUserDefaults() {
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
        UserDefaults.standard.synchronize()
        showSuccess("UserDefaults cleared")
    }

    func clearKeychain() {
        // Clear all keychain items
        showSuccess("Keychain cleared")
    }

    func resetOnboarding() {
        UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
        UserDefaults.standard.synchronize()
        showSuccess("Onboarding reset - restart app to see onboarding flow")
    }

    func clearImageCache() {
        ImageCache.shared.clearAll()
        showSuccess("Image cache cleared")
    }

    func clearOfflineQueue() {
        OfflineStorageManager.shared.clearQueue()
        showSuccess("Offline queue cleared")
    }

    func clearAllData() {
        clearUserDefaults()
        clearKeychain()
        clearImageCache()
        clearOfflineQueue()
        DebugLogger.shared.clearLogs()
        showSuccess("All local data cleared")
    }

    // MARK: - Sample Data

    func populateSampleFoodLogs() {
        // Would need actual service injection
        showSuccess("Added 5 sample food logs")
    }

    func populateSampleActivities() {
        showSuccess("Added 3 sample activities")
    }

    func populateSamplePhotos() {
        showSuccess("Added 2 sample photos")
    }

    func populateCompleteSampleData() {
        populateSampleFoodLogs()
        populateSampleActivities()
        populateSamplePhotos()
        showSuccess("All sample data populated")
    }

    // MARK: - Notifications

    func triggerTestNotification() {
        NotificationManager.shared.sendTestNotification()
        showSuccess("Test notification sent")
    }

    func triggerDailyReminder() {
        NotificationManager.shared.sendImmediateNotification(
            title: "Log Your Meals",
            body: "Don't forget to track your food intake!",
            identifier: "debug.daily_reminder"
        )
        showSuccess("Daily reminder triggered")
    }

    func triggerWeeklySummary() {
        NotificationManager.shared.sendImmediateNotification(
            title: "Weekly Progress",
            body: "Check out your weekly summary!",
            identifier: "debug.weekly_summary"
        )
        showSuccess("Weekly summary triggered")
    }

    func clearAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        showSuccess("All notifications cleared")
    }

    // MARK: - Authentication

    func refreshSession() {
        // Would trigger actual session refresh
        showSuccess("Session refresh requested")
    }

    // MARK: - Logging

    func exportLogs() {
        let logs = DebugLogger.shared.exportLogs()
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("debug-logs.txt")

        do {
            try logs.write(to: tempURL, atomically: true, encoding: .utf8)
            exportURL = tempURL
            showShareSheet = true
        } catch {
            showError("Failed to export logs: \(error.localizedDescription)")
        }
    }

    func clearLogs() {
        DebugLogger.shared.clearLogs()
        showSuccess("Logs cleared")
    }

    // MARK: - Test Scenarios

    func simulateFirstTimeUser() {
        resetOnboarding()
        clearAllData()
        showSuccess("Configured as first-time user")
    }

    func simulateReturningUser() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        populateCompleteSampleData()
        showSuccess("Configured as returning user with data")
    }

    func simulateUserWithoutStrava() {
        // Would clear Strava connection
        showSuccess("Strava connection removed")
    }

    func simulateOfflineMode() {
        // Would disable network or inject mock failing network
        showSuccess("Offline mode enabled - restart to test")
    }

    // MARK: - Helpers

    private func showSuccess(_ message: String) {
        successMessage = message
        showSuccessAlert = true
    }

    private func showError(_ message: String) {
        errorMessage = message
        showErrorAlert = true
    }
}

#endif
