//
//  ProfileView.swift
//  Netfuel
//
//  View for user profile and settings
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var appState: AppState

    private var userName: String {
        // Use name if available, otherwise derive from email
        if let name = appState.currentUser?.name, !name.isEmpty {
            return name
        }
        return appState.currentUser?.email?.components(separatedBy: "@").first?.capitalized ?? "User"
    }

    var body: some View {
        NavigationView {
            List {
                // User info section
                Section {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.red.gradient)
                            .accessibilityHidden(true)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(userName)
                                .font(.title3)
                                .fontWeight(.semibold)

                            Text(appState.currentUser?.email ?? "")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.leading, 8)
                    }
                    .padding(.vertical, 8)
                    .accessible(label: "User profile: \(userName), \(appState.currentUser?.email ?? "")", traits: .isStaticText)
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
                    .accessibilityLabel("Edit profile")
                    .accessibilityHint("Opens profile editor to update physical stats")
                    
                    if let weight = appState.currentUser?.weight {
                        LabeledContent("Weight", value: UnitFormatter.formatWeight(weight))
                    } else {
                        LabeledContent("Weight", value: "Not set")
                    }

                    if let height = appState.currentUser?.height {
                        LabeledContent("Height", value: UnitFormatter.formatHeight(height))
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
                                    .accessibilityHidden(true)
                            }
                        }
                        .accessibilityLabel("Strava integration")
                        .accessibilityHint("Connect or manage Strava account for activity syncing")
                    }
                }

                // Progress photos section
                Section("Progress") {
                    NavigationLink {
                        ProgressPhotoGalleryView()
                    } label: {
                        HStack {
                            Image(systemName: "photo.on.rectangle.angled")
                                .foregroundColor(.purple)
                            Text("Progress Photos")

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .accessibilityHidden(true)
                        }
                    }
                    .accessibilityLabel("Progress photos")
                    .accessibilityHint("View and manage progress photos")
                }

                // Goals section
                Section("Goals") {
                    if let userId = appState.currentUser?.id {
                        NavigationLink {
                            GoalsSettingsView(viewModel: SettingsViewModel(userId: userId))
                        } label: {
                            HStack {
                                Image(systemName: "target")
                                    .foregroundColor(.red)
                                Text("Goals & Targets")

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .accessibilityHidden(true)
                            }
                        }
                        .accessibilityLabel("Goals and targets")
                        .accessibilityHint("Set daily calorie and macro targets")

                        NavigationLink {
                            QuickAddSettingsView()
                        } label: {
                            HStack {
                                Image(systemName: "bolt.circle.fill")
                                    .foregroundColor(.orange)
                                Text("Quick-Add Buttons")

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .accessibilityHidden(true)
                            }
                        }
                        .accessibilityLabel("Quick-add buttons")
                        .accessibilityHint("Configure quick-add buttons for frequently logged foods")
                    }
                }

                // Settings section
                Section("Settings") {
                    if let userId = appState.currentUser?.id {
                        NavigationLink {
                            SettingsView(userId: userId)
                        } label: {
                            HStack {
                                Image(systemName: "gear")
                                    .foregroundColor(.gray)
                                Text("Settings & Preferences")

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .accessibilityHidden(true)
                            }
                        }
                        .accessibilityLabel("Settings and preferences")
                        .accessibilityHint("Configure app settings")
                    }
                }
            }
            .navigationTitle("Profile")
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AppState())
}

