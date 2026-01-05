//
//  StravaConnectionView.swift
//  Netfuel
//
//  View for managing Strava connection and syncing activities
//

import SwiftUI

struct StravaConnectionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel: StravaViewModel
    @State private var showingDisconnectAlert = false

    init(userId: UUID) {
        _viewModel = StateObject(wrappedValue: StravaViewModel(userId: userId))
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection

                    // Connection Status
                    connectionStatusSection

                    // Error/Success Messages
                    if let errorMessage = viewModel.errorMessage {
                        messageView(message: errorMessage, type: .error)
                    }

                    if let successMessage = viewModel.successMessage {
                        messageView(message: successMessage, type: .success)
                    }

                    // Connect/Disconnect Button
                    actionButtonSection

                    // Activities Summary (if connected)
                    if viewModel.isConnected {
                        activitiesSummarySection
                    }

                    // About Strava Integration
                    aboutSection
                }
                .padding()
            }
            .navigationTitle("Strava")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .refreshable {
                if viewModel.isConnected {
                    await viewModel.refreshActivities()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .stravaOAuthCallback)) { notification in
                // Handle Strava OAuth callback
                if let code = notification.userInfo?["code"] as? String {
                    print("✅ StravaConnectionView received OAuth callback with code")
                    Task {
                        await viewModel.handleOAuthCallback(code: code)
                    }
                }
            }
            .alert("Disconnect Strava?", isPresented: $showingDisconnectAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Disconnect", role: .destructive) {
                    Task {
                        await viewModel.disconnect()
                    }
                }
            } message: {
                Text("Your activities will remain saved, but no new activities will be synced.")
            }
        }
    }
    
    // MARK: - View Components
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "figure.run")
                .font(.system(size: 60))
                .foregroundStyle(.orange.gradient)
            
            Text("Strava Integration")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Sync your activities to track exercise calories")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var connectionStatusSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Connection Status")
                        .font(.headline)
                    
                    Text(viewModel.connectionStatusText)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: viewModel.isConnected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(viewModel.isConnected ? .green : .gray)
            }
            
            if let connection = viewModel.connection {
                Divider()
                
                VStack(spacing: 12) {
                    athleteInfoRow(label: "Athlete ID", value: connection.athleteId)
                    
                    if let username = connection.athleteUsername {
                        athleteInfoRow(label: "Username", value: username)
                    }
                    
                    if let fullName = connection.athleteFullName {
                        athleteInfoRow(label: "Name", value: fullName)
                    }
                    
                    athleteInfoRow(
                        label: "Connected",
                        value: connection.connectedAt.formatted(date: .abbreviated, time: .shortened)
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }
    
    private func athleteInfoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
    
    private var actionButtonSection: some View {
        VStack(spacing: 12) {
            if viewModel.isConnected {
                // Sync Button
                Button {
                    Task {
                        await viewModel.syncActivities()
                    }
                } label: {
                    HStack {
                        if viewModel.isSyncing {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white)
                        } else {
                            Image(systemName: "arrow.triangle.2.circlepath")
                            Text(viewModel.syncButtonText)
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                }
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(12)
                .disabled(viewModel.isSyncing)
                
                // Disconnect Button
                Button(role: .destructive) {
                    showingDisconnectAlert = true
                } label: {
                    Text("Disconnect Strava")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                }
                .background(Color.red.opacity(0.1))
                .foregroundColor(.red)
                .cornerRadius(12)
                .disabled(viewModel.isLoading)
                
            } else {
                // Connect Button
                Button {
                    viewModel.connectStrava()
                } label: {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white)
                        } else {
                            Image(systemName: "link")
                            Text("Connect to Strava")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                }
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(12)
                .disabled(viewModel.isLoading)
            }
        }
    }
    
    private var activitiesSummarySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Activities")
                    .font(.headline)
                
                Spacer()
                
                NavigationLink {
                    ActivityListView(userId: appState.currentUser?.id ?? UUID())
                } label: {
                    Text("View All")
                        .font(.subheadline)
                        .foregroundColor(.orange)
                }
            }
            
            if viewModel.activities.isEmpty {
                emptyActivitiesView
            } else {
                ForEach(viewModel.activities.prefix(3)) { activity in
                    ActivityRowView(activity: activity)
                }
                
                if viewModel.activities.count > 3 {
                    Text("+ \(viewModel.activities.count - 3) more activities")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }
    
    private var emptyActivitiesView: some View {
        VStack(spacing: 12) {
            Image(systemName: "figure.walk")
                .font(.system(size: 40))
                .foregroundColor(.gray)
            
            Text("No activities synced yet")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("Tap 'Sync Activities' to import from Strava")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
    
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("About Strava Integration")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                bulletPoint("Automatically sync your runs, rides, and other activities")
                bulletPoint("Track exercise calories for accurate TDEE calculation")
                bulletPoint("View detailed activity metrics and stats")
                bulletPoint("Your Strava data is securely stored")
            }
            
            Text("Powered by Strava API v3")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 8)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.caption)
                .foregroundColor(.orange)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private func messageView(message: String, type: MessageType) -> some View {
        HStack(spacing: 12) {
            Image(systemName: type.icon)
                .foregroundColor(type.color)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
        }
        .padding()
        .background(type.color.opacity(0.1))
        .cornerRadius(8)
    }
    
    enum MessageType {
        case success, error
        
        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .error: return "exclamationmark.triangle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .success: return .green
            case .error: return .red
            }
        }
    }
}

// MARK: - Activity Row View

struct ActivityRowView: View {
    let activity: Activity
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: activityIcon)
                    .font(.title3)
                    .foregroundColor(.orange)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(activity.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(activity.type)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(activity.calories) cal")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                    
                    Text(activity.startDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack(spacing: 16) {
                if let distance = activity.formattedDistance {
                    metricView(icon: "figure.walk", value: distance)
                }
                
                metricView(icon: "clock", value: activity.formattedDuration)
                
                if let pace = activity.formattedPace {
                    metricView(icon: "speedometer", value: pace)
                }
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private var activityIcon: String {
        switch activity.type.lowercased() {
        case let t where t.contains("run"):
            return "figure.run"
        case let t where t.contains("ride") || t.contains("bike"):
            return "bicycle"
        case let t where t.contains("swim"):
            return "figure.pool.swim"
        case let t where t.contains("walk") || t.contains("hike"):
            return "figure.walk"
        default:
            return "figure.mixed.cardio"
        }
    }
    
    private func metricView(icon: String, value: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
            Text(value)
        }
    }
}

#Preview {
    NavigationView {
        StravaConnectionView(userId: UUID())
            .environmentObject(AppState())
    }
}

