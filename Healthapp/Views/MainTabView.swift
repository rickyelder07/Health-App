//
//  MainTabView.swift
//  Netfuel
//
//  Main tab view container for app navigation
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab: Tab = .home
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(Tab.home)
            
            // Calendar Tab
            CalendarView()
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }
                .tag(Tab.calendar)
            
            // Food Log Tab (Center)
            FoodLogListView()
                .tabItem {
                    Label("Food", systemImage: "fork.knife")
                }
                .tag(Tab.add)
            
            // Analytics Tab
            if let userId = appState.currentUser?.id {
                AnalyticsView(userId: userId)
                    .tabItem {
                        Label("Analytics", systemImage: "chart.line.uptrend.xyaxis")
                    }
                    .tag(Tab.analytics)
            }

            // Profile Tab
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(Tab.profile)
        }
        .accentColor(.red)
    }
}

/// Tab enumeration for navigation
enum Tab {
    case home
    case calendar
    case add
    case analytics
    case profile
}

#Preview {
    MainTabView()
        .environmentObject(AppState())
}

