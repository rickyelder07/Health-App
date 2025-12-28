//
//  FoodSearchView.swift
//  Health App
//
//  View for searching foods (USDA, custom foods, custom meals)
//

import SwiftUI

/// Main food search view with tabs for USDA, Custom Foods, and Custom Meals
struct FoodSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var usdaViewModel = FoodSearchViewModel()
    @ObservedObject var foodViewModel: FoodViewModel
    
    @State private var selectedTab: FoodSearchTab = .usda
    @State private var searchText: String = ""
    @State private var showingCreateFood = false
    @State private var showingCreateMeal = false
    @State private var selectedFood: USDAFood?
    @State private var selectedCustomFood: CustomFood?
    @State private var selectedCustomMeal: CustomMeal?
    
    enum FoodSearchTab: String, CaseIterable {
        case usda = "USDA"
        case myFoods = "My Foods"
        case myMeals = "My Meals"
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Segmented Control
                Picker("Source", selection: $selectedTab) {
                    ForEach(FoodSearchTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search \(selectedTab.rawValue.lowercased())...", text: $searchText)
                        .textFieldStyle(.plain)
                        .autocorrectionDisabled()
                        .onChange(of: searchText) { _ in
                            performSearch()
                        }
                    
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Content based on selected tab
                Group {
                    switch selectedTab {
                    case .usda:
                        USDAFoodsListView(
                            viewModel: usdaViewModel,
                            foodViewModel: foodViewModel,
                            searchText: searchText,
                            onSelect: { food in
                                selectedFood = food
                            }
                        )
                        
                    case .myFoods:
                        CustomFoodsListView(
                            viewModel: foodViewModel,
                            searchText: searchText,
                            onSelect: { food in
                                selectedCustomFood = food
                            },
                            onCreate: {
                                showingCreateFood = true
                            }
                        )
                        
                    case .myMeals:
                        CustomMealsListView(
                            viewModel: foodViewModel,
                            searchText: searchText,
                            onSelect: { meal in
                                selectedCustomMeal = meal
                            },
                            onCreate: {
                                showingCreateMeal = true
                            }
                        )
                    }
                }
            }
            .navigationTitle("Add Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    if selectedTab == .myFoods {
                        Button {
                            showingCreateFood = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                        }
                    } else if selectedTab == .myMeals {
                        Button {
                            showingCreateMeal = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingCreateFood) {
                CreateCustomFoodView(viewModel: foodViewModel)
            }
            .sheet(isPresented: $showingCreateMeal) {
                CreateCustomMealView(viewModel: foodViewModel)
            }
            .sheet(item: $selectedFood) { food in
                FoodDetailView(
                    usdaFood: food,
                    foodViewModel: foodViewModel,
                    onLog: {
                        dismiss()
                    }
                )
            }
            .sheet(item: $selectedCustomFood) { food in
                FoodDetailView(
                    customFood: food,
                    foodViewModel: foodViewModel,
                    onLog: {
                        dismiss()
                    }
                )
            }
            .sheet(item: $selectedCustomMeal) { meal in
                MealDetailView(
                    foodViewModel: foodViewModel,
                    meal: meal,
                    onLogCallback: {
                        dismiss()
                    }
                )
            }
        }
    }
    
    private func performSearch() {
        switch selectedTab {
        case .usda:
            usdaViewModel.searchText = searchText
            usdaViewModel.performSearch()
        case .myFoods, .myMeals:
            // Search handled in respective list views
            break
        }
    }
}

// MARK: - USDA Foods List

struct USDAFoodsListView: View {
    @ObservedObject var viewModel: FoodSearchViewModel
    @ObservedObject var foodViewModel: FoodViewModel
    let searchText: String
    let onSelect: (USDAFood) -> Void
    
    var body: some View {
        if viewModel.isSearching {
            VStack(spacing: 16) {
                ProgressView()
                Text("Searching...")
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
        } else if let errorMessage = viewModel.errorMessage {
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 50))
                    .foregroundColor(.orange)
                Text(errorMessage)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
        } else if !viewModel.searchResults.isEmpty {
            List(viewModel.searchResults) { food in
                Button {
                    onSelect(food)
                } label: {
                    USDAFoodRow(food: food, foodViewModel: foodViewModel)
                }
                .buttonStyle(.plain)
            }
            .listStyle(.plain)
            
        } else if searchText.isEmpty {
            EmptySearchView(
                icon: "magnifyingglass",
                title: "Search USDA Database",
                message: "Search for foods from the USDA FoodData Central database"
            )
        } else {
            EmptySearchView(
                icon: "questionmark.circle",
                title: "No Results",
                message: "No foods found for '\(searchText)'"
            )
        }
    }
}

// MARK: - Custom Foods List

struct CustomFoodsListView: View {
    @ObservedObject var viewModel: FoodViewModel
    let searchText: String
    let onSelect: (CustomFood) -> Void
    let onCreate: () -> Void
    
    private var filteredFoods: [CustomFood] {
        if searchText.isEmpty {
            return viewModel.customFoods
        }
        return viewModel.customFoods.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.brand?.localizedCaseInsensitiveContains(searchText) == true
        }
    }
    
    private var favoriteFoods: [CustomFood] {
        filteredFoods.filter { $0.isFavorite }
    }
    
    private var regularFoods: [CustomFood] {
        filteredFoods.filter { !$0.isFavorite }
    }
    
    var body: some View {
        if filteredFoods.isEmpty {
            if viewModel.customFoods.isEmpty {
                EmptyStateView(
                    icon: "fork.knife",
                    title: "No Custom Foods Yet",
                    message: "Create your own foods with custom nutrition info",
                    actionTitle: "Create Food",
                    action: onCreate
                )
            } else {
                EmptySearchView(
                    icon: "questionmark.circle",
                    title: "No Results",
                    message: "No custom foods found for '\(searchText)'"
                )
            }
        } else {
            List {
                if !favoriteFoods.isEmpty {
                    Section("Favorites") {
                        ForEach(favoriteFoods) { food in
                            Button {
                                onSelect(food)
                            } label: {
                                CustomFoodRow(food: food, viewModel: viewModel)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                if !regularFoods.isEmpty {
                    Section(favoriteFoods.isEmpty ? "All Foods" : "Other Foods") {
                        ForEach(regularFoods) { food in
                            Button {
                                onSelect(food)
                            } label: {
                                CustomFoodRow(food: food, viewModel: viewModel)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
    }
}

// MARK: - Custom Meals List

struct CustomMealsListView: View {
    @ObservedObject var viewModel: FoodViewModel
    let searchText: String
    let onSelect: (CustomMeal) -> Void
    let onCreate: () -> Void
    
    private var filteredMeals: [CustomMeal] {
        if searchText.isEmpty {
            return viewModel.customMeals
        }
        return viewModel.customMeals.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.description?.localizedCaseInsensitiveContains(searchText) == true
        }
    }
    
    private var favoriteMeals: [CustomMeal] {
        filteredMeals.filter { $0.isFavorite }
    }
    
    private var regularMeals: [CustomMeal] {
        filteredMeals.filter { !$0.isFavorite }
    }
    
    var body: some View {
        if filteredMeals.isEmpty {
            if viewModel.customMeals.isEmpty {
                EmptyStateView(
                    icon: "star",
                    title: "No Custom Meals Yet",
                    message: "Create meals by combining multiple foods",
                    actionTitle: "Create Meal",
                    action: onCreate
                )
            } else {
                EmptySearchView(
                    icon: "questionmark.circle",
                    title: "No Results",
                    message: "No custom meals found for '\(searchText)'"
                )
            }
        } else {
            List {
                if !favoriteMeals.isEmpty {
                    Section("Favorites") {
                        ForEach(favoriteMeals) { meal in
                            Button {
                                onSelect(meal)
                            } label: {
                                CustomMealRow(meal: meal, viewModel: viewModel)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                if !regularMeals.isEmpty {
                    Section(favoriteMeals.isEmpty ? "All Meals" : "Other Meals") {
                        ForEach(regularMeals) { meal in
                            Button {
                                onSelect(meal)
                            } label: {
                                CustomMealRow(meal: meal, viewModel: viewModel)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
    }
}

// MARK: - Row Views

struct USDAFoodRow: View {
    let food: USDAFood
    @ObservedObject var foodViewModel: FoodViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(food.description)
                .font(.headline)
                .lineLimit(2)
            
            if let brandName = food.brandName {
                Text(brandName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            InlineMacroView(
                calories: Int(food.calories ?? 0),
                protein: food.protein ?? 0,
                carbs: food.carbohydrates ?? 0,
                fat: food.fat ?? 0
            )
        }
        .padding(.vertical, 4)
        .contextMenu {
            Button {
                Task {
                    _ = await foodViewModel.createCustomFoodFromUSDA(food)
                }
            } label: {
                Label("Copy to My Foods", systemImage: "doc.on.doc")
            }
        }
    }
}

struct CustomFoodRow: View {
    let food: CustomFood
    @ObservedObject var viewModel: FoodViewModel
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    if food.isFavorite {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                    }
                    
                    Text(food.displayName)
                        .font(.headline)
                        .lineLimit(2)
                }
                
                Text(food.servingDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                InlineMacroView(
                    calories: food.calories,
                    protein: food.protein,
                    carbs: food.carbs,
                    fat: food.fat
                )
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct CustomMealRow: View {
    let meal: CustomMeal
    @ObservedObject var viewModel: FoodViewModel
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    if meal.isFavorite {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                    }
                    
                    Text(meal.name)
                        .font(.headline)
                        .lineLimit(2)
                }
                
                if let description = meal.description, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                InlineMacroView(
                    calories: meal.totalCalories,
                    protein: meal.totalProtein,
                    carbs: meal.totalCarbs,
                    fat: meal.totalFat
                )
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Empty States

struct EmptySearchView: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.title3)
                .fontWeight(.medium)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 60))
                    .foregroundColor(.secondary)
                
                Text(title)
                    .font(.title3)
                    .fontWeight(.medium)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Button(action: action) {
                Text(actionTitle)
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: 200)
                    .padding()
                    .background(Color.accentColor)
                    .cornerRadius(12)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    FoodSearchView(foodViewModel: FoodViewModel())
}

