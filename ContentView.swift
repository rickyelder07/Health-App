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
                MainTabView()
            } else {
                AuthenticationView()
            }
        }
        .animation(.easeInOut, value: appState.isAuthenticated)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}

