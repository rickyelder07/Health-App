//
//  ProfileView.swift
//  Health App
//
//  View for user profile and settings
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingSignOutAlert = false
    
    var body: some View {
        NavigationView {
            List {
                // User info section
                Section {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.red.gradient)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(appState.currentUser?.email?.components(separatedBy: "@").first?.capitalized ?? "User")
                                .font(.title3)
                                .fontWeight(.semibold)
                            
                            Text(appState.currentUser?.email ?? "")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.leading, 8)
                    }
                    .padding(.vertical, 8)
                }
                
                // Physical stats section
                Section("Physical Stats") {
                    NavigationLink {
                        EditProfileView(appState: appState)
                    } label: {
                        HStack {
                            Image(systemName: "person.fill")
                            Text("Edit Profile")
                        }
                    }
                    
                    if let weight = appState.currentUser?.weight {
                        LabeledContent("Weight", value: "\(String(format: "%.1f", weight)) kg")
                    } else {
                        LabeledContent("Weight", value: "Not set")
                    }
                    
                    if let height = appState.currentUser?.height {
                        LabeledContent("Height", value: "\(String(format: "%.0f", height)) cm")
                    } else {
                        LabeledContent("Height", value: "Not set")
                    }
                    
                    if let age = appState.currentUser?.age {
                        LabeledContent("Age", value: "\(age) years")
                    } else {
                        LabeledContent("Age", value: "Not set")
                    }
                    
                    if let gender = appState.currentUser?.gender {
                        LabeledContent("Gender", value: gender.displayName)
                    } else {
                        LabeledContent("Gender", value: "Not set")
                    }
                }
                
                // Calorie info section
                Section("Daily Calories") {
                    // Show stored BMR or calculate it if possible
                    if let user = appState.currentUser {
                        if let bmr = user.bmr {
                            LabeledContent("BMR", value: "\(Int(bmr)) cal")
                        } else if let calculatedBMR = user.calculateBMR() {
                            LabeledContent("BMR", value: "\(Int(calculatedBMR)) cal")
                                .foregroundColor(.secondary)
                        } else {
                            LabeledContent("BMR", value: "Not calculated")
                                .foregroundColor(.secondary)
                        }
                        
                        // Show stored TDEE or calculate it if possible
                        if let tdee = user.tdee {
                            LabeledContent("TDEE", value: "\(Int(tdee)) cal")
                        } else if let calculatedTDEE = user.calculateTDEE() {
                            LabeledContent("TDEE", value: "\(Int(calculatedTDEE)) cal")
                                .foregroundColor(.secondary)
                        } else {
                            LabeledContent("TDEE", value: "Not calculated")
                                .foregroundColor(.secondary)
                        }
                        
                        if let activityLevel = user.activityLevel {
                            LabeledContent("Activity Level", value: activityLevel.displayName)
                        } else {
                            LabeledContent("Activity Level", value: "Not set")
                        }
                    }
                }
                
                // Integrations section
                Section("Integrations") {
                    if let userId = appState.currentUser?.id {
                        NavigationLink {
                            StravaConnectionView(userId: userId)
                        } label: {
                            HStack {
                                Image(systemName: "figure.run")
                                    .foregroundColor(.orange)
                                Text("Strava")
                                
                                Spacer()
                                
                                // Connection status indicator will be shown in the view itself
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                // Progress photos section
                Section("Progress") {
                    NavigationLink {
                        Text("Progress Photos")
                    } label: {
                        HStack {
                            Image(systemName: "photo.on.rectangle")
                            Text("Progress Photos")
                        }
                    }
                }
                
                // Settings section
                Section("Settings") {
                    NavigationLink {
                        Text("App Settings")
                    } label: {
                        HStack {
                            Image(systemName: "gear")
                            Text("App Settings")
                        }
                    }
                    
                    NavigationLink {
                        Text("About")
                    } label: {
                        HStack {
                            Image(systemName: "info.circle")
                            Text("About")
                        }
                    }
                }
                
                // Sign out section
                Section {
                    Button(role: .destructive) {
                        showingSignOutAlert = true
                    } label: {
                        HStack {
                            Spacer()
                            Text("Sign Out")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Profile")
            .alert("Sign Out", isPresented: $showingSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    Task {
                        await appState.signOut()
                    }
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AppState())
}

