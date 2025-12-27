//
//  MainTabView.swift
//  Health App
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
            
            // Add Food Tab (Center)
            AddFoodView()
                .tabItem {
                    Label("Add", systemImage: "plus.circle.fill")
                }
                .tag(Tab.add)
            
            // Activities Tab
            ActivitiesView()
                .tabItem {
                    Label("Activities", systemImage: "figure.run")
                }
                .tag(Tab.activities)
            
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
    case activities
    case profile
}

#Preview {
    MainTabView()
        .environmentObject(AppState())
}

