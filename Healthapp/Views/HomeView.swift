//
//  HomeView.swift
//  Health App
//
//  Home screen displaying daily calorie summary
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel: HomeViewModel
    @State private var showingStravaSync = false
    @State private var stravaSyncMessage: String?
    
    init() {
        // Initialize with temporary UUID - will be updated with actual user ID
        _viewModel = StateObject(wrappedValue: HomeViewModel(userId: UUID()))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Hello, \(appState.currentUser?.email?.components(separatedBy: "@").first?.capitalized ?? "User")!")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text(Date().formatted(date: .long, time: .omitted))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Calorie summary card
                    if let summary = viewModel.dailySummary {
                        CalorieSummaryCard(summary: summary)
                            .padding(.horizontal)
                    } else {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .frame(height: 200)
                    }
                    
                    // Macros summary
                    if let summary = viewModel.dailySummary {
                        MacrosSummaryView(summary: summary)
                            .padding(.horizontal)
                    }
                    
                    // Quick actions
                    QuickActionsView()
                        .padding(.horizontal)
                    
                    // Recent food entries
                    RecentEntriesSection(entries: viewModel.foodEntries)
                        .padding(.horizontal)
                    
                    Spacer()
                }
            }
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                await viewModel.refresh()
            }
            .task {
                await viewModel.loadTodaySummary()
            }
        }
    }
}

// MARK: - Calorie Summary Card

struct CalorieSummaryCard: View {
    let summary: DailySummary
    
    var totalBurned: Int {
        summary.totalCaloriesBurned ?? summary.calculateTotalCaloriesBurned()
    }
    
    var netCalories: Int {
        summary.netCalories ?? summary.calculateNetCalories()
    }
    
    var isInSurplus: Bool {
        netCalories > 0
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Circular progress
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 20)
                
                Circle()
                    .trim(from: 0, to: 0.5) // Placeholder progress
                    .stroke(
                        isInSurplus ? Color.orange : Color.green,
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 4) {
                    Text("\(abs(netCalories))")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                    Text(isInSurplus ? "surplus" : "deficit")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 200, height: 200)
            
            // Stats row
            HStack(spacing: 30) {
                StatItem(
                    icon: "flame.fill",
                    color: .orange,
                    value: totalBurned,
                    label: "Burned"
                )
                
                StatItem(
                    icon: "fork.knife",
                    color: .blue,
                    value: summary.caloriesConsumed,
                    label: "Food"
                )
                
                StatItem(
                    icon: "figure.run",
                    color: .green,
                    value: summary.caloriesBurnedExercise,
                    label: "Exercise"
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

struct StatItem: View {
    let icon: String
    let color: Color
    let value: Int
    let label: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text("\(value)")
                .font(.headline)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Macros Summary

struct MacrosSummaryView: View {
    let summary: DailySummary
    
    // Rough macro targets (can be customized later)
    var proteinTarget: Double { Double(summary.caloriesConsumed) * 0.30 / 4 } // 30% of calories, 4 cal/g
    var carbsTarget: Double { Double(summary.caloriesConsumed) * 0.40 / 4 } // 40% of calories, 4 cal/g
    var fatTarget: Double { Double(summary.caloriesConsumed) * 0.30 / 9 } // 30% of calories, 9 cal/g
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Macronutrients")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                MacroRow(
                    name: "Protein",
                    current: summary.proteinConsumed,
                    target: proteinTarget,
                    color: .red,
                    unit: "g"
                )
                
                MacroRow(
                    name: "Carbs",
                    current: summary.carbsConsumed,
                    target: carbsTarget,
                    color: .blue,
                    unit: "g"
                )
                
                MacroRow(
                    name: "Fat",
                    current: summary.fatConsumed,
                    target: fatTarget,
                    color: .orange,
                    unit: "g"
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

struct MacroRow: View {
    let name: String
    let current: Double
    let target: Double
    let color: Color
    let unit: String
    
    var progress: Double {
        guard target > 0 else { return 0 }
        return min(current / target, 1.0)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("\(Int(current)) / \(Int(target)) \(unit)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(color)
                        .frame(width: geometry.size.width * progress, height: 8)
                        .cornerRadius(4)
                        .animation(.easeInOut, value: progress)
                }
            }
            .frame(height: 8)
        }
    }
}

// MARK: - Quick Actions

struct QuickActionsView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 12) {
                QuickActionButton(
                    icon: "plus.circle.fill",
                    title: "Log Food",
                    color: .blue
                ) {
                    // Navigate to add food
                }
                
                QuickActionButton(
                    icon: "camera.fill",
                    title: "Progress Photo",
                    color: .purple
                ) {
                    // Navigate to add photo
                }
                
                NavigationLink {
                    if let userId = appState.currentUser?.id {
                        StravaConnectionView(userId: userId)
                    } else {
                        Text("Please sign in to sync Strava")
                    }
                } label: {
                    QuickActionButtonLabel(
                        icon: "arrow.triangle.2.circlepath",
                        title: "Sync Strava",
                        color: .orange
                    )
                }
            }
        }
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            QuickActionButtonLabel(icon: icon, title: title, color: color)
        }
    }
}

struct QuickActionButtonLabel: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.gradient)
        .cornerRadius(12)
    }
}

// MARK: - Recent Entries

struct RecentEntriesSection: View {
    let entries: [FoodEntry]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Entries")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("See All") {
                    // Navigate to all entries
                }
                .font(.caption)
                .foregroundColor(.accentColor)
            }
            
            if entries.isEmpty {
                Text("No food entries yet")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(entries.prefix(5)) { entry in
                    FoodEntryRow(entry: entry)
                }
            }
        }
    }
}

struct FoodEntryRow: View {
    let entry: FoodEntry
    
    var body: some View {
        HStack {
            Image(systemName: entry.mealType?.icon ?? "fork.knife")
                .foregroundColor(.accentColor)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.foodName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(String(format: "%.1f serving", entry.servings))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("\(Int(entry.totalCalories)) cal")
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    HomeView()
        .environmentObject(AppState())
}

