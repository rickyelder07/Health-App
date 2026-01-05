//
//  ContentView.swift
//  Health App
//
//  Root view that handles navigation between authentication, onboarding, and main app
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @AppStorage("onboarding_completed") private var isOnboardingCompleted: Bool = false

    var body: some View {
        Group {
            if appState.isAuthenticated {
                // Check if user has completed onboarding
                if !isOnboardingCompleted {
                    // Show onboarding for first-time users
                    OnboardingView(isOnboardingCompleted: $isOnboardingCompleted)
                } else if let user = appState.currentUser, user.hasCompleteProfile {
                    // Show main app for users with complete profile
                    MainTabView()
                } else {
                    // Show profile setup for users who skipped it in onboarding or have incomplete profiles
                    ProfileSetupView(appState: appState)
                }
            } else {
                AuthenticationView()
            }
        }
        .animation(.easeInOut, value: appState.isAuthenticated)
        .animation(.easeInOut, value: isOnboardingCompleted)
        .animation(.easeInOut, value: appState.currentUser?.hasCompleteProfile)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}

