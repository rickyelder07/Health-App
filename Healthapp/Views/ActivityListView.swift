//
//  ActivityListView.swift
//  Health App
//
//  View for displaying all Strava activities with filtering
//

import SwiftUI

struct ActivityListView: View {
    @StateObject private var viewModel: StravaViewModel
    @State private var selectedFilter: ActivityFilter = .all
    @State private var showingFilterSheet = false
    
    init(userId: UUID) {
        _viewModel = StateObject(wrappedValue: StravaViewModel(userId: userId))
    }
    
    var body: some View {
        List {
            // Filter Section
            Section {
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(ActivityFilter.allCases, id: \.self) { filter in
                        Text(filter.displayName).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            // Activities List
            Section {
                if filteredActivities.isEmpty {
                    emptyStateView
                } else {
                    ForEach(filteredActivities) { activity in
                        NavigationLink {
                            ActivityDetailView(activity: activity)
                        } label: {
                            ActivityListRow(activity: activity)
                        }
                    }
                }
            } header: {
                HStack {
                    Text("Activities")
                    Spacer()
                    Text("\(filteredActivities.count) total")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Activities")
        .navigationBarTitleDisplayMode(.large)
        .refreshable {
            await viewModel.refreshActivities()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task {
                        await viewModel.syncActivities()
                    }
                } label: {
                    if viewModel.isSyncing {
                        ProgressView()
                            .progressViewStyle(.circular)
                    } else {
                        Image(systemName: "arrow.triangle.2.circlepath")
                    }
                }
                .disabled(viewModel.isSyncing)
            }
        }
        .overlay {
            if viewModel.isLoading && viewModel.activities.isEmpty {
                ProgressView("Loading activities...")
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var filteredActivities: [Activity] {
        switch selectedFilter {
        case .all:
            return viewModel.activities
        case .runs:
            return viewModel.activities.filter { $0.type.lowercased().contains("run") }
        case .rides:
            return viewModel.activities.filter { $0.type.lowercased().contains("ride") || $0.type.lowercased().contains("bike") }
        case .other:
            return viewModel.activities.filter {
                !$0.type.lowercased().contains("run") &&
                !$0.type.lowercased().contains("ride") &&
                !$0.type.lowercased().contains("bike")
            }
        case .thisWeek:
            let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
            return viewModel.activities.filter { $0.startDate >= weekAgo }
        case .thisMonth:
            let monthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
            return viewModel.activities.filter { $0.startDate >= monthAgo }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.run")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Activities")
                .font(.headline)
            
            Text("Pull to refresh or sync from Strava")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .listRowBackground(Color.clear)
    }
}

// MARK: - Activity List Row

struct ActivityListRow: View {
    let activity: Activity
    
    var body: some View {
        HStack(spacing: 12) {
            // Activity Icon
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Image(systemName: activityIcon)
                    .font(.title3)
                    .foregroundColor(.orange)
            }
            
            // Activity Details
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text(activity.type)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 12) {
                    if let distance = activity.formattedDistance {
                        Label(distance, systemImage: "figure.walk")
                            .font(.caption2)
                    }
                    
                    Label(activity.formattedDuration, systemImage: "clock")
                        .font(.caption2)
                }
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Calories and Date
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(activity.calories)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.orange)
                
                Text("cal")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text(activity.startDate.formatted(date: .numeric, time: .omitted))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
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
}

// MARK: - Activity Detail View

struct ActivityDetailView: View {
    let activity: Activity
    
    var body: some View {
        List {
            // Header Section
            Section {
                VStack(spacing: 16) {
                    Image(systemName: activityIcon)
                        .font(.system(size: 60))
                        .foregroundStyle(.orange.gradient)
                    
                    Text(activity.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text(activity.type)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(activity.startDate.formatted(date: .long, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical)
            }
            .listRowBackground(Color.clear)
            
            // Primary Metrics
            Section("Summary") {
                MetricRow(icon: "flame.fill", label: "Calories", value: "\(activity.calories) cal", color: .orange)
                
                if let distance = activity.formattedDistance {
                    MetricRow(icon: "figure.walk", label: "Distance", value: distance, color: .blue)
                }
                
                MetricRow(icon: "clock.fill", label: "Duration", value: activity.formattedDuration, color: .green)
                
                if let pace = activity.formattedPace {
                    MetricRow(icon: "speedometer", label: "Pace", value: pace, color: .purple)
                }
            }
            
            // Performance Metrics
            if activity.averageSpeed != nil || activity.averageHeartrate != nil || activity.elevationGain != nil {
                Section("Performance") {
                    if let speed = activity.formattedSpeed {
                        MetricRow(icon: "gauge.high", label: "Avg Speed", value: speed, color: .indigo)
                    }
                    
                    if let maxSpeed = activity.maxSpeed {
                        let maxSpeedKmh = maxSpeed * 3.6
                        MetricRow(icon: "gauge.high", label: "Max Speed", value: String(format: "%.1f km/h", maxSpeedKmh), color: .indigo)
                    }
                    
                    if let avgHR = activity.averageHeartrate {
                        MetricRow(icon: "heart.fill", label: "Avg Heart Rate", value: "\(Int(avgHR)) bpm", color: .red)
                    }
                    
                    if let maxHR = activity.maxHeartrate {
                        MetricRow(icon: "heart.fill", label: "Max Heart Rate", value: "\(maxHR) bpm", color: .red)
                    }
                    
                    if let elevation = activity.elevationGain {
                        MetricRow(icon: "mountain.2.fill", label: "Elevation Gain", value: String(format: "%.0f m", elevation), color: .brown)
                    }
                }
            }
            
            // Strava Info
            Section("Source") {
                HStack {
                    Image(systemName: "link")
                    Text("Strava Activity ID")
                    Spacer()
                    Text("\(activity.stravaId)")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Activity Details")
        .navigationBarTitleDisplayMode(.inline)
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
}

// MARK: - Metric Row

struct MetricRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 30)
            
            Text(label)
                .font(.subheadline)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Activity Filter

enum ActivityFilter: String, CaseIterable {
    case all = "All"
    case runs = "Runs"
    case rides = "Rides"
    case other = "Other"
    case thisWeek = "This Week"
    case thisMonth = "This Month"
    
    var displayName: String {
        return self.rawValue
    }
}

#Preview {
    NavigationView {
        ActivityListView(userId: UUID())
    }
}

