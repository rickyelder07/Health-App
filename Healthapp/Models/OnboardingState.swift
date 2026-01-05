//
//  OnboardingState.swift
//  Netfuel
//
//  Manages onboarding completion state and page tracking
//

import Foundation

/// Onboarding pages enum
enum OnboardingPage: Int, CaseIterable {
    case welcome = 0
    case features
    case profileSetup
    case stravaConnection
    case permissions
    case ready

    var title: String {
        switch self {
        case .welcome:
            return "Welcome to Health Tracker"
        case .features:
            return "Track Your Health"
        case .profileSetup:
            return "Set Up Your Profile"
        case .stravaConnection:
            return "Connect Strava"
        case .permissions:
            return "Enable Permissions"
        case .ready:
            return "You're All Set!"
        }
    }

    var description: String {
        switch self {
        case .welcome:
            return "Your personal calorie and fitness tracker"
        case .features:
            return "Log food, track exercise, and monitor progress"
        case .profileSetup:
            return "Tell us about yourself to calculate your daily calorie needs"
        case .stravaConnection:
            return "Sync your activities automatically (optional)"
        case .permissions:
            return "Grant access for the best experience"
        case .ready:
            return "Start tracking your health journey today"
        }
    }

    var icon: String {
        switch self {
        case .welcome:
            return "heart.circle.fill"
        case .features:
            return "list.clipboard.fill"
        case .profileSetup:
            return "person.circle.fill"
        case .stravaConnection:
            return "figure.run.circle.fill"
        case .permissions:
            return "checkmark.shield.fill"
        case .ready:
            return "checkmark.circle.fill"
        }
    }

    /// Whether this page can be skipped
    var isSkippable: Bool {
        switch self {
        case .welcome, .ready:
            return false
        case .features, .stravaConnection, .permissions:
            return true
        case .profileSetup:
            return false  // Profile setup is required
        }
    }
}

/// Onboarding state manager with UserDefaults persistence
struct OnboardingState {
    private static let onboardingCompletedKey = "onboarding_completed"
    private static let profileSetupCompletedKey = "profile_setup_completed_in_onboarding"
    private static let stravaConnectionCompletedKey = "strava_connection_completed_in_onboarding"
    private static let permissionsRequestedKey = "permissions_requested_in_onboarding"

    /// Check if user has completed onboarding
    static var isOnboardingCompleted: Bool {
        get {
            UserDefaults.standard.bool(forKey: onboardingCompletedKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: onboardingCompletedKey)
            print("📱 Onboarding completion status set to: \(newValue)")
        }
    }

    /// Check if profile setup was completed during onboarding
    static var isProfileSetupCompleted: Bool {
        get {
            UserDefaults.standard.bool(forKey: profileSetupCompletedKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: profileSetupCompletedKey)
        }
    }

    /// Check if Strava connection was completed during onboarding
    static var isStravaConnectionCompleted: Bool {
        get {
            UserDefaults.standard.bool(forKey: stravaConnectionCompletedKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: stravaConnectionCompletedKey)
        }
    }

    /// Check if permissions were requested during onboarding
    static var arePermissionsRequested: Bool {
        get {
            UserDefaults.standard.bool(forKey: permissionsRequestedKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: permissionsRequestedKey)
        }
    }

    /// Mark onboarding as complete
    static func completeOnboarding() {
        isOnboardingCompleted = true
        print("✅ Onboarding marked as completed")
    }

    /// Reset onboarding state (for testing)
    static func resetOnboarding() {
        UserDefaults.standard.removeObject(forKey: onboardingCompletedKey)
        UserDefaults.standard.removeObject(forKey: profileSetupCompletedKey)
        UserDefaults.standard.removeObject(forKey: stravaConnectionCompletedKey)
        UserDefaults.standard.removeObject(forKey: permissionsRequestedKey)
        print("🔄 Onboarding state reset")
    }
}
