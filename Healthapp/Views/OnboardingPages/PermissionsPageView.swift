//
//  PermissionsPageView.swift
//  Netfuel
//
//  Permissions request page for onboarding
//

import SwiftUI
import Photos
import UserNotifications

struct PermissionsPageView: View {
    @ObservedObject var onboardingViewModel: OnboardingViewModel
    @State private var cameraStatus: AuthorizationStatus = .notDetermined
    @State private var photosStatus: AuthorizationStatus = .notDetermined
    @State private var notificationsStatus: AuthorizationStatus = .notDetermined

    enum AuthorizationStatus {
        case notDetermined
        case authorized
        case denied

        var icon: String {
            switch self {
            case .notDetermined: return "circle"
            case .authorized: return "checkmark.circle.fill"
            case .denied: return "xmark.circle.fill"
            }
        }

        var color: Color {
            switch self {
            case .notDetermined: return .gray
            case .authorized: return .green
            case .denied: return .red
            }
        }
    }

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Icon
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 100))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .blue.opacity(0.3), radius: 20, x: 0, y: 10)

            // Title
            VStack(spacing: 12) {
                Text("Enable Permissions")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Grant access for the best experience")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Permissions List
            VStack(spacing: 20) {
                PermissionRow(
                    icon: "photo.fill",
                    title: "Photos",
                    description: "Take and upload progress photos",
                    status: photosStatus,
                    action: requestPhotoPermission
                )

                PermissionRow(
                    icon: "bell.fill",
                    title: "Notifications",
                    description: "Get reminders and updates",
                    status: notificationsStatus,
                    action: requestNotificationPermission
                )
            }
            .padding(.horizontal, 20)

            Spacer()

            // Request All Button
            if photosStatus == .notDetermined || notificationsStatus == .notDetermined {
                Button {
                    requestAllPermissions()
                } label: {
                    HStack {
                        Image(systemName: "checkmark.shield.fill")
                        Text("Grant Permissions")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 40)
            } else {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)

                    Text("Permissions Configured")
                        .font(.headline)
                        .foregroundColor(.green)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal, 40)
            }

            // Optional Note
            Text("You can change these later in Settings")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()
        }
        .padding()
        .onAppear {
            checkPermissionStatuses()
        }
    }

    // MARK: - Permission Methods

    private func checkPermissionStatuses() {
        // Check Photos permission
        let photoStatus = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        switch photoStatus {
        case .authorized, .limited:
            photosStatus = .authorized
        case .denied, .restricted:
            photosStatus = .denied
        case .notDetermined:
            photosStatus = .notDetermined
        @unknown default:
            photosStatus = .notDetermined
        }

        // Check Notifications permission
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .authorized, .provisional:
                    notificationsStatus = .authorized
                case .denied:
                    notificationsStatus = .denied
                case .notDetermined:
                    notificationsStatus = .notDetermined
                @unknown default:
                    notificationsStatus = .notDetermined
                }
            }
        }
    }

    private func requestPhotoPermission() {
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized, .limited:
                    photosStatus = .authorized
                case .denied, .restricted:
                    photosStatus = .denied
                case .notDetermined:
                    photosStatus = .notDetermined
                @unknown default:
                    photosStatus = .notDetermined
                }
                checkAllPermissions()
            }
        }
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    notificationsStatus = .authorized
                } else {
                    notificationsStatus = .denied
                }
                checkAllPermissions()
            }
        }
    }

    private func requestAllPermissions() {
        if photosStatus == .notDetermined {
            requestPhotoPermission()
        }
        if notificationsStatus == .notDetermined {
            requestNotificationPermission()
        }
    }

    private func checkAllPermissions() {
        // Mark permissions as requested if user has made a decision on either
        if photosStatus != .notDetermined || notificationsStatus != .notDetermined {
            onboardingViewModel.completePermissions()
        }
    }
}

struct PermissionRow: View {
    let icon: String
    let title: String
    let description: String
    let status: PermissionsPageView.AuthorizationStatus
    let action: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(12)

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Status
            Button {
                if status == .notDetermined {
                    action()
                }
            } label: {
                Image(systemName: status.icon)
                    .font(.title3)
                    .foregroundColor(status.color)
            }
            .disabled(status != .notDetermined)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    PermissionsPageView(onboardingViewModel: OnboardingViewModel())
}
