//
//  OnboardingViewModel.swift
//  Netfuel
//
//  ViewModel for onboarding flow management
//

import Foundation
import SwiftUI
import Combine

/// ViewModel managing onboarding flow state and navigation
@MainActor
class OnboardingViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var currentPage: OnboardingPage = .welcome
    @Published var isProfileSetupComplete: Bool = false
    @Published var isStravaConnected: Bool = false
    @Published var permissionsGranted: Bool = false
    @Published var shouldDismiss: Bool = false

    // MARK: - Computed Properties

    /// Current page index
    var currentPageIndex: Int {
        currentPage.rawValue
    }

    /// Total number of pages
    var totalPages: Int {
        OnboardingPage.allCases.count
    }

    /// Whether user can go to next page
    var canGoNext: Bool {
        switch currentPage {
        case .profileSetup:
            // Can only proceed if profile is complete
            return isProfileSetupComplete
        default:
            return currentPageIndex < totalPages - 1
        }
    }

    /// Whether user can go back
    var canGoBack: Bool {
        currentPageIndex > 0
    }

    /// Whether current page can be skipped
    var canSkip: Bool {
        currentPage.isSkippable
    }

    /// Progress percentage (0.0 to 1.0)
    var progress: Double {
        Double(currentPageIndex + 1) / Double(totalPages)
    }

    // MARK: - Navigation Methods

    /// Navigate to next page
    func goToNextPage() {
        guard canGoNext else {
            print("⚠️ Cannot go to next page from \(currentPage)")
            return
        }

        let nextIndex = currentPageIndex + 1
        if nextIndex < totalPages {
            currentPage = OnboardingPage(rawValue: nextIndex) ?? .welcome
            print("📱 Navigated to page: \(currentPage)")
        }
    }

    /// Navigate to previous page
    func goToPreviousPage() {
        guard canGoBack else {
            print("⚠️ Cannot go back from \(currentPage)")
            return
        }

        let previousIndex = currentPageIndex - 1
        if previousIndex >= 0 {
            currentPage = OnboardingPage(rawValue: previousIndex) ?? .welcome
            print("📱 Navigated back to page: \(currentPage)")
        }
    }

    /// Skip current page
    func skipPage() {
        guard canSkip else {
            print("⚠️ Cannot skip page: \(currentPage)")
            return
        }

        print("📱 Skipping page: \(currentPage)")
        goToNextPage()
    }

    /// Navigate to specific page
    func goToPage(_ page: OnboardingPage) {
        currentPage = page
        print("📱 Jumped to page: \(currentPage)")
    }

    // MARK: - Completion Methods

    /// Mark profile setup as complete
    func completeProfileSetup() {
        print("📱 Marking profile setup as complete...")
        isProfileSetupComplete = true
        OnboardingState.isProfileSetupCompleted = true
        print("✅ Profile setup marked as complete. isProfileSetupComplete = \(isProfileSetupComplete)")
    }

    /// Mark Strava connection as complete
    func completeStravaConnection() {
        isStravaConnected = true
        OnboardingState.isStravaConnectionCompleted = true
        print("✅ Strava connection marked as complete")
    }

    /// Mark permissions as granted
    func completePermissions() {
        permissionsGranted = true
        OnboardingState.arePermissionsRequested = true
        print("✅ Permissions marked as granted")
    }

    /// Complete entire onboarding process
    func completeOnboarding() {
        OnboardingState.completeOnboarding()
        shouldDismiss = true
        print("✅ Onboarding completed, dismissing")
    }

    // MARK: - Validation

    /// Check if user can complete onboarding
    var canCompleteOnboarding: Bool {
        // Profile setup is required, everything else is optional
        return isProfileSetupComplete
    }
}
