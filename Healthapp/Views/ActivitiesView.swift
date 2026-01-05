//
//  ActivitiesView.swift
//  Netfuel
//
//  View for displaying Strava activities
//

import SwiftUI

struct ActivitiesView: View {
    @State private var activities: [Activity] = []
    @State private var isConnectedToStrava = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if !isConnectedToStrava {
                        // Strava connection prompt
                        VStack(spacing: 16) {
                            Image(systemName: "figure.run.circle.fill")
                                .font(.system(size: 60))
                                .foregroundStyle(.orange.gradient)
                            
                            Text("Connect to Strava")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("Sync your activities to automatically track exercise calories")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            Button {
                                // Handle Strava OAuth
                            } label: {
                                HStack {
                                    Image(systemName: "link")
                                    Text("Connect Strava")
                                }
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.orange)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            .padding(.horizontal)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                        .padding()
                    } else {
                        // Activities list
                        if activities.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "figure.run")
                                    .font(.system(size: 50))
                                    .foregroundColor(.secondary)
                                
                                Text("No activities yet")
                                    .font(.headline)
                                
                                Text("Your Strava activities will appear here")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxHeight: .infinity)
                            .padding()
                        } else {
                            ForEach(activities) { activity in
                                ActivityRow(activity: activity)
                                    .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.top)
            }
            .navigationTitle("Activities")
            .toolbar {
                if isConnectedToStrava {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            // Sync activities
                        } label: {
                            Image(systemName: "arrow.triangle.2.circlepath")
                        }
                    }
                }
            }
        }
    }
}

struct ActivityRow: View {
    let activity: Activity
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(activity.name)
                        .font(.headline)
                    
                    Text(activity.type)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(activity.calories) cal")
                        .font(.headline)
                        .foregroundColor(.orange)
                    
                    Text(activity.startDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Activity stats
            HStack(spacing: 20) {
                if let distance = activity.formattedDistance {
                    StatLabel(icon: "location.fill", value: distance)
                }
                
                StatLabel(icon: "clock.fill", value: activity.formattedDuration)
                
                if let pace = activity.formattedPace {
                    StatLabel(icon: "speedometer", value: pace)
                }
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct StatLabel: View {
    let icon: String
    let value: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
            Text(value)
        }
    }
}

#Preview {
    ActivitiesView()
}

