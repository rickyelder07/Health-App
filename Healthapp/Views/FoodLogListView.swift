//
//  FoodLogListView.swift
//  Health App
//
//  View for displaying today's food logs with macro tracking
//

import SwiftUI

/// Main food logging view with today's logs and macro progress
struct FoodLogListView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = FoodViewModel()
    
    @State private var showingAddFood = false
    @State private var selectedDate = Date()
    @State private var showingDatePicker = false
    
    // Sample targets (should come from user profile)
    private let caloriesTarget = 2200
    private let proteinTarget = 150.0
    private let carbsTarget = 200.0
    private let fatTarget = 70.0
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Date Selector
                    DateSelectorView(
                        selectedDate: $selectedDate,
                        onDateChange: {
                            Task {
                                await viewModel.refreshTodayLogs()
                            }
                        }
                    )
                    .padding(.horizontal)
                    
                    // Macro Progress Summary
                    MacroSummaryCard(
                        calories: viewModel.todayTotalCalories,
                        caloriesTarget: caloriesTarget,
                        protein: viewModel.todayTotalProtein,
                        proteinTarget: proteinTarget,
                        carbs: viewModel.todayTotalCarbs,
                        carbsTarget: carbsTarget,
                        fat: viewModel.todayTotalFat,
                        fatTarget: fatTarget
                    )
                    .padding(.horizontal)
                    
                    // Food Logs by Meal Type
                    FoodLogsByMealView(
                        viewModel: viewModel,
                        onDelete: { log in
                            Task {
                                await viewModel.deleteFoodLog(log)
                            }
                        }
                    )
                    .padding(.horizontal)
                    
                    // Quick Add Section
                    if !viewModel.recentFoods.isEmpty {
                        QuickAddSection(
                            recentFoods: viewModel.recentFoods,
                            onSelect: { log in
                                // Quick log recent food
                                Task {
                                    _ = await viewModel.logFood(
                                        foodName: log.foodName,
                                        brandName: log.brandName,
                                        servingSize: log.servingSize,
                                        servingUnit: log.servingUnit,
                                        calories: log.calories,
                                        protein: log.protein,
                                        carbs: log.carbs,
                                        fat: log.fat,
                                        fiber: log.fiber,
                                        sugar: log.sugar,
                                        sodium: log.sodium,
                                        servings: log.servings,
                                        mealType: log.mealType
                                    )
                                }
                            }
                        )
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Food Log")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddFood = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showingAddFood) {
                FoodSearchView(foodViewModel: viewModel)
            }
            .refreshable {
                await viewModel.refreshTodayLogs()
            }
            .task {
                if let userId = appState.currentUser?.id {
                    viewModel.setUser(userId: userId)
                }
            }
            .alert("Success", isPresented: Binding(
                get: { viewModel.successMessage != nil },
                set: { if !$0 { viewModel.clearMessages() } }
            )) {
                Button("OK") {
                    viewModel.clearMessages()
                }
            } message: {
                if let message = viewModel.successMessage {
                    Text(message)
                }
            }
            .alert("Error", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.clearMessages() } }
            )) {
                Button("OK") {
                    viewModel.clearMessages()
                }
            } message: {
                if let message = viewModel.errorMessage {
                    Text(message)
                }
            }
        }
    }
}

// MARK: - Date Selector

struct DateSelectorView: View {
    @Binding var selectedDate: Date
    let onDateChange: () -> Void
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: selectedDate)
    }
    
    var body: some View {
        HStack {
            Button {
                selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
                onDateChange()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .foregroundColor(.accentColor)
            }
            
            Spacer()
            
            VStack(spacing: 4) {
                Text(formattedDate)
                    .font(.headline)
                
                if isToday {
                    Text("Today")
                        .font(.caption)
                        .foregroundColor(.accentColor)
                }
            }
            
            Spacer()
            
            Button {
                selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
                onDateChange()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .foregroundColor(.accentColor)
            }
            .disabled(isToday)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Food Logs by Meal

struct FoodLogsByMealView: View {
    @ObservedObject var viewModel: FoodViewModel
    let onDelete: (FoodLog) -> Void
    
    private var logsByMeal: [MealType: [FoodLog]] {
        viewModel.foodLogsByMealType()
    }
    
    var body: some View {
        VStack(spacing: 16) {
            ForEach(MealType.allCases, id: \.self) { mealType in
                if let logs = logsByMeal[mealType], !logs.isEmpty {
                    MealSection(
                        mealType: mealType,
                        logs: logs,
                        onDelete: onDelete
                    )
                } else {
                    EmptyMealSection(mealType: mealType)
                }
            }
        }
    }
}

// MARK: - Meal Section

struct MealSection: View {
    let mealType: MealType
    let logs: [FoodLog]
    let onDelete: (FoodLog) -> Void
    
    private var totalCalories: Int {
        logs.reduce(0) { $0 + Int($1.totalCalories) }
    }
    
    private var totalProtein: Double {
        logs.reduce(0.0) { $0 + $1.totalProtein }
    }
    
    private var totalCarbs: Double {
        logs.reduce(0.0) { $0 + $1.totalCarbs }
    }
    
    private var totalFat: Double {
        logs.reduce(0.0) { $0 + $1.totalFat }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: mealType.icon)
                        .foregroundColor(.accentColor)
                    Text(mealType.displayName)
                        .font(.headline)
                }
                
                Spacer()
                
                Text("\(totalCalories) cal")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
            }
            
            // Food logs
            VStack(spacing: 8) {
                ForEach(logs) { log in
                    FoodLogRow(log: log, onDelete: {
                        onDelete(log)
                    })
                }
            }
            
            // Meal totals
            HStack(spacing: 16) {
                MacroBadge(icon: "p.circle.fill", value: String(format: "%.0f", totalProtein), unit: "g", color: .red)
                MacroBadge(icon: "c.circle.fill", value: String(format: "%.0f", totalCarbs), unit: "g", color: .blue)
                MacroBadge(icon: "f.circle.fill", value: String(format: "%.0f", totalFat), unit: "g", color: .purple)
            }
            .padding(.top, 4)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Empty Meal Section

struct EmptyMealSection: View {
    let mealType: MealType
    
    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: mealType.icon)
                    .foregroundColor(.secondary)
                Text(mealType.displayName)
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("No foods logged")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Food Log Row

struct FoodLogRow: View {
    let log: FoodLog
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(log.foodName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if let brand = log.brandName {
                    Text(brand)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(log.servingDescription)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                InlineMacroView(
                    calories: Int(log.totalCalories),
                    protein: log.totalProtein,
                    carbs: log.totalCarbs,
                    fat: log.totalFat
                )
            }
            
            Spacer()
            
            Button {
                onDelete()
            } label: {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - Quick Add Section

struct QuickAddSection: View {
    let recentFoods: [FoodLog]
    let onSelect: (FoodLog) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recently Logged")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(recentFoods.prefix(5)) { log in
                        QuickAddCard(log: log, onTap: {
                            onSelect(log)
                        })
                    }
                }
            }
        }
    }
}

// MARK: - Quick Add Card

struct QuickAddCard: View {
    let log: FoodLog
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                Text(log.foodName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Text("\(log.calories) cal")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 4) {
                    Image(systemName: "plus.circle.fill")
                        .font(.caption)
                    Text("Quick Add")
                        .font(.caption2)
                }
                .foregroundColor(.accentColor)
            }
            .frame(width: 140)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    FoodLogListView()
        .environmentObject(AppState())
}

