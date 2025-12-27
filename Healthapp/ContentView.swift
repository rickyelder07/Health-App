//
//  ContentView.swift
//  Health App
//
//  Root view that handles navigation between authentication and main app
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        Group {
            if appState.isAuthenticated {
                // Check if user has complete profile
                if let user = appState.currentUser, user.hasCompleteProfile {
                    MainTabView()
                } else {
                    // Show profile setup for first-time users or incomplete profiles
                    ProfileSetupView(appState: appState)
                }
            } else {
                AuthenticationView()
            }
        }
        .animation(.easeInOut, value: appState.isAuthenticated)
        .animation(.easeInOut, value: appState.currentUser?.hasCompleteProfile)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}

