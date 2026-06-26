//
//  NotificationSettingsView.swift
//  Netfuel
//
//  Configure notification preferences
//

import SwiftUI

struct NotificationSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var preferences = NotificationManager.shared.preferences
    @State private var notificationStatus: String = "Checking..."
    @State private var showingPermissionAlert = false

    var body: some View {
        NavigationView {
            Form {
                // Permission Status Section
                Section {
                    HStack {
                        Image(systemName: permissionIcon)
                            .foregroundColor(permissionColor)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Notification Status")
                                .font(.subheadline)
                                .fontWeight(.medium)

                            Text(notificationStatus)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        if notificationStatus == "Not Authorized" {
                            Button("Enable") {
                                showingPermissionAlert = true
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                    }
                } header: {
                    Text("Permissions")
                }

                // Meal Reminders
                Section {
                    MealReminderRow(
                        label: "Breakfast",
                        icon: "sunrise.fill",
                        isOn: $preferences.breakfastReminderEnabled,
                        time: $preferences.breakfastTime
                    ) { saveAndReschedule() }
                } header: {
                    Text("Breakfast Reminder")
                } footer: {
                    Text("Only fires if you haven't logged breakfast yet.")
                }

                Section {
                    MealReminderRow(
                        label: "Lunch",
                        icon: "sun.max.fill",
                        isOn: $preferences.lunchReminderEnabled,
                        time: $preferences.lunchTime
                    ) { saveAndReschedule() }
                } header: {
                    Text("Lunch Reminder")
                } footer: {
                    Text("Only fires if you haven't logged lunch yet.")
                }

                Section {
                    MealReminderRow(
                        label: "Dinner",
                        icon: "moon.fill",
                        isOn: $preferences.dinnerReminderEnabled,
                        time: $preferences.dinnerTime
                    ) { saveAndReschedule() }
                } header: {
                    Text("Dinner Reminder")
                } footer: {
                    Text("Only fires if you haven't logged dinner yet.")
                }

                // Strava Sync Reminder
                Section {
                    Toggle("Sync Reminder", isOn: $preferences.stravaSyncReminderEnabled)
                        .onChange(of: preferences.stravaSyncReminderEnabled) { newValue in
                            if newValue {
                                NotificationManager.shared.scheduleStravaSyncReminder()
                            } else {
                                NotificationManager.shared.cancelStravaSyncReminder()
                            }
                            savePreferences()
                        }

                    if preferences.stravaSyncReminderEnabled {
                        Text("Get reminded to sync your Strava activities")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Strava")
                }

                // Weekly Progress Summary
                Section {
                    Toggle("Weekly Summary", isOn: $preferences.weeklyProgressSummaryEnabled)
                        .onChange(of: preferences.weeklyProgressSummaryEnabled) { newValue in
                            if newValue {
                                NotificationManager.shared.scheduleWeeklyProgressSummary(
                                    weekday: preferences.weeklyProgressDay,
                                    hour: preferences.weeklyProgressHour
                                )
                            } else {
                                NotificationManager.shared.cancelWeeklyProgressSummary()
                            }
                            savePreferences()
                        }

                    if preferences.weeklyProgressSummaryEnabled {
                        Picker("Day", selection: $preferences.weeklyProgressDay) {
                            ForEach(1...7, id: \.self) { day in
                                Text(dayName(for: day))
                                    .tag(day)
                            }
                        }
                        .onChange(of: preferences.weeklyProgressDay) { _ in
                            NotificationManager.shared.scheduleWeeklyProgressSummary(
                                weekday: preferences.weeklyProgressDay,
                                hour: preferences.weeklyProgressHour
                            )
                            savePreferences()
                        }

                        Picker("Time", selection: $preferences.weeklyProgressHour) {
                            ForEach(0...23, id: \.self) { hour in
                                Text(timeString(for: hour))
                                    .tag(hour)
                            }
                        }
                        .onChange(of: preferences.weeklyProgressHour) { _ in
                            NotificationManager.shared.scheduleWeeklyProgressSummary(
                                weekday: preferences.weeklyProgressDay,
                                hour: preferences.weeklyProgressHour
                            )
                            savePreferences()
                        }

                        Text("Get a summary of your progress every week")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Progress")
                }

                // Test Notification
                Section {
                    Button {
                        HapticFeedback.light()
                        NotificationManager.shared.sendInstantNotification(
                            title: "Test Notification",
                            body: "Your notifications are working perfectly!"
                        )
                    } label: {
                        HStack {
                            Image(systemName: "bell.badge")
                            Text("Send Test Notification")
                        }
                    }
                } header: {
                    Text("Testing")
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                await checkPermissionStatus()
            }
            .alert("Notifications Disabled", isPresented: $showingPermissionAlert) {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Please enable notifications in Settings to receive reminders and updates.")
            }
        }
    }

    // MARK: - Helper Methods

    private func savePreferences() {
        preferences.save()
    }

    private func saveAndReschedule() {
        preferences.save()
        NotificationManager.shared.scheduleMealReminders()
    }

    private func checkPermissionStatus() async {
        let status = await NotificationManager.shared.checkPermissionStatus()

        await MainActor.run {
            switch status {
            case .authorized:
                notificationStatus = "Authorized"
            case .denied:
                notificationStatus = "Not Authorized"
            case .notDetermined:
                notificationStatus = "Not Requested"
            case .provisional:
                notificationStatus = "Provisional"
            case .ephemeral:
                notificationStatus = "Ephemeral"
            @unknown default:
                notificationStatus = "Unknown"
            }
        }
    }

    private var permissionIcon: String {
        switch notificationStatus {
        case "Authorized", "Provisional":
            return "checkmark.circle.fill"
        case "Not Authorized":
            return "xmark.circle.fill"
        default:
            return "bell.circle"
        }
    }

    private var permissionColor: Color {
        switch notificationStatus {
        case "Authorized", "Provisional":
            return .green
        case "Not Authorized":
            return .red
        default:
            return .orange
        }
    }

    private func dayName(for day: Int) -> String {
        Calendar.current.weekdaySymbols[day - 1]
    }

    private func timeString(for hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:00 a"

        var components = DateComponents()
        components.hour = hour
        let date = Calendar.current.date(from: components) ?? Date()

        return formatter.string(from: date)
    }
}

private struct MealReminderRow: View {
    let label: String
    let icon: String
    @Binding var isOn: Bool
    @Binding var time: Date
    let onChange: () -> Void

    var body: some View {
        Toggle(isOn: $isOn) {
            Label(label, systemImage: icon)
        }
        .onChange(of: isOn) { _ in onChange() }

        if isOn {
            DatePicker("Reminder Time", selection: $time, displayedComponents: .hourAndMinute)
                .onChange(of: time) { _ in onChange() }
        }
    }
}

#Preview {
    NotificationSettingsView()
}
