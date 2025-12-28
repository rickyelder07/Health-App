//
//  FoodViewModel.swift
//  Health App
//
//  ViewModel for food logging with custom foods and meals
//

import Foundation
import Combine

/// Main ViewModel for food logging features
@MainActor
class FoodViewModel: ObservableObject {
    // MARK: - Published Properties
    
    // Custom Foods
    @Published var customFoods: [CustomFood] = []
    @Published var favoriteCustomFoods: [CustomFood] = []
    
    // Custom Meals
    @Published var customMeals: [CustomMeal] = []
    @Published var favoriteCustomMeals: [CustomMeal] = []
    @Published var selectedMealFoods: [CustomMealFood] = []
    
    // Food Logs
    @Published var todayFoodLogs: [FoodLog] = []
    @Published var recentFoods: [FoodLog] = []
    
    // UI State
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    // Selection State
    @Published var selectedFood: CustomFood?
    @Published var selectedMeal: CustomMeal?
    
    // MARK: - Private Properties
    
    private let foodService = FoodService()
    private var userId: UUID?
    
    // MARK: - Initialization
    
    func setUser(userId: UUID) {
        self.userId = userId
        Task {
            await loadInitialData()
        }
    }
    
    // MARK: - Data Loading
    
    /// Load all initial data
    func loadInitialData() async {
        guard let userId = userId else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            async let customFoodsTask = foodService.fetchCustomFoods(userId: userId)
            async let customMealsTask = foodService.fetchCustomMeals(userId: userId)
            async let todayLogsTask = foodService.fetchFoodLogs(userId: userId, date: Date())
            async let recentTask = foodService.fetchRecentFoods(userId: userId, limit: 10)
            
            customFoods = try await customFoodsTask
            customMeals = try await customMealsTask
            todayFoodLogs = try await todayLogsTask
            recentFoods = try await recentTask
            
            // Filter favorites
            favoriteCustomFoods = customFoods.filter { $0.isFavorite }
            favoriteCustomMeals = customMeals.filter { $0.isFavorite }
            
        } catch {
            errorMessage = "Failed to load data: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Refresh custom foods
    func refreshCustomFoods() async {
        guard let userId = userId else { return }
        
        do {
            customFoods = try await foodService.fetchCustomFoods(userId: userId)
            favoriteCustomFoods = customFoods.filter { $0.isFavorite }
        } catch {
            errorMessage = "Failed to refresh custom foods: \(error.localizedDescription)"
        }
    }
    
    /// Refresh custom meals
    func refreshCustomMeals() async {
        guard let userId = userId else { return }
        
        do {
            customMeals = try await foodService.fetchCustomMeals(userId: userId)
            favoriteCustomMeals = customMeals.filter { $0.isFavorite }
        } catch {
            errorMessage = "Failed to refresh custom meals: \(error.localizedDescription)"
        }
    }
    
    /// Refresh today's food logs
    func refreshTodayLogs() async {
        guard let userId = userId else { return }
        
        do {
            todayFoodLogs = try await foodService.fetchFoodLogs(userId: userId, date: Date())
        } catch {
            errorMessage = "Failed to refresh food logs: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Custom Food Operations
    
    /// Create custom food
    func createCustomFood(
        name: String,
        brand: String?,
        calories: Int,
        protein: Double,
        carbs: Double,
        fat: Double,
        fiber: Double?,
        sugar: Double?,
        sodium: Double?,
        servingSize: String,
        servingUnit: String,
        isFavorite: Bool
    ) async -> Bool {
        guard let userId = userId else { return false }
        
        isLoading = true
        errorMessage = nil
        
        let request = CreateCustomFoodRequest(
            userId: userId,
            name: name,
            brand: brand,
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            fiber: fiber,
            sugar: sugar,
            sodium: sodium,
            servingSize: servingSize,
            servingUnit: servingUnit,
            isFavorite: isFavorite
        )
        
        do {
            let newFood = try await foodService.createCustomFood(request: request)
            customFoods.insert(newFood, at: 0)
            if isFavorite {
                favoriteCustomFoods.insert(newFood, at: 0)
            }
            successMessage = "Custom food created!"
            isLoading = false
            return true
        } catch {
            errorMessage = "Failed to create food: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    /// Update custom food
    func updateCustomFood(
        foodId: UUID,
        name: String?,
        brand: String?,
        calories: Int?,
        protein: Double?,
        carbs: Double?,
        fat: Double?,
        fiber: Double?,
        sugar: Double?,
        sodium: Double?,
        servingSize: String?,
        servingUnit: String?,
        isFavorite: Bool?
    ) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        let request = UpdateCustomFoodRequest(
            name: name,
            brand: brand,
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            fiber: fiber,
            sugar: sugar,
            sodium: sodium,
            servingSize: servingSize,
            servingUnit: servingUnit,
            isFavorite: isFavorite
        )
        
        do {
            let updatedFood = try await foodService.updateCustomFood(foodId: foodId, request: request)
            if let index = customFoods.firstIndex(where: { $0.id == foodId }) {
                customFoods[index] = updatedFood
            }
            await refreshCustomFoods()
            successMessage = "Food updated!"
            isLoading = false
            return true
        } catch {
            errorMessage = "Failed to update food: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    /// Delete custom food
    func deleteCustomFood(foodId: UUID) async {
        do {
            try await foodService.deleteCustomFood(foodId: foodId)
            customFoods.removeAll { $0.id == foodId }
            favoriteCustomFoods.removeAll { $0.id == foodId }
            successMessage = "Food deleted"
        } catch {
            errorMessage = "Failed to delete food: \(error.localizedDescription)"
        }
    }
    
    /// Toggle custom food favorite
    func toggleCustomFoodFavorite(_ food: CustomFood) async {
        do {
            try await foodService.toggleCustomFoodFavorite(foodId: food.id, isFavorite: !food.isFavorite)
            await refreshCustomFoods()
        } catch {
            errorMessage = "Failed to update favorite: \(error.localizedDescription)"
        }
    }
    
    /// Create custom food from USDA food
    func createCustomFoodFromUSDA(_ usdaFood: USDAFood) async -> CustomFood? {
        guard let userId = userId else { return nil }
        
        do {
            let customFood = try await foodService.createCustomFoodFromUSDA(usdaFood: usdaFood, userId: userId)
            customFoods.insert(customFood, at: 0)
            successMessage = "Food added to your custom foods!"
            return customFood
        } catch {
            errorMessage = "Failed to create custom food: \(error.localizedDescription)"
            return nil
        }
    }
    
    // MARK: - Custom Meal Operations
    
    /// Create custom meal
    func createCustomMeal(name: String, description: String?, isFavorite: Bool) async -> CustomMeal? {
        guard let userId = userId else { return nil }
        
        isLoading = true
        errorMessage = nil
        
        let request = CreateCustomMealRequest(
            userId: userId,
            name: name,
            description: description,
            isFavorite: isFavorite
        )
        
        do {
            let newMeal = try await foodService.createCustomMeal(request: request)
            customMeals.insert(newMeal, at: 0)
            if isFavorite {
                favoriteCustomMeals.insert(newMeal, at: 0)
            }
            successMessage = "Meal created!"
            isLoading = false
            return newMeal
        } catch {
            errorMessage = "Failed to create meal: \(error.localizedDescription)"
            isLoading = false
            return nil
        }
    }
    
    /// Update custom meal
    func updateCustomMeal(mealId: UUID, name: String?, description: String?, isFavorite: Bool?) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        let request = UpdateCustomMealRequest(name: name, description: description, isFavorite: isFavorite)
        
        do {
            let updatedMeal = try await foodService.updateCustomMeal(mealId: mealId, request: request)
            if let index = customMeals.firstIndex(where: { $0.id == mealId }) {
                customMeals[index] = updatedMeal
            }
            await refreshCustomMeals()
            successMessage = "Meal updated!"
            isLoading = false
            return true
        } catch {
            errorMessage = "Failed to update meal: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    /// Delete custom meal
    func deleteCustomMeal(mealId: UUID) async {
        do {
            try await foodService.deleteCustomMeal(mealId: mealId)
            customMeals.removeAll { $0.id == mealId }
            favoriteCustomMeals.removeAll { $0.id == mealId }
            successMessage = "Meal deleted"
        } catch {
            errorMessage = "Failed to delete meal: \(error.localizedDescription)"
        }
    }
    
    /// Toggle custom meal favorite
    func toggleCustomMealFavorite(_ meal: CustomMeal) async {
        do {
            try await foodService.toggleCustomMealFavorite(mealId: meal.id, isFavorite: !meal.isFavorite)
            await refreshCustomMeals()
        } catch {
            errorMessage = "Failed to update favorite: \(error.localizedDescription)"
        }
    }
    
    /// Duplicate custom meal
    func duplicateCustomMeal(_ meal: CustomMeal, newName: String) async {
        guard let userId = userId else { return }
        
        isLoading = true
        
        do {
            let duplicatedMeal = try await foodService.duplicateCustomMeal(
                mealId: meal.id,
                newName: newName,
                userId: userId
            )
            customMeals.insert(duplicatedMeal, at: 0)
            successMessage = "Meal duplicated!"
        } catch {
            errorMessage = "Failed to duplicate meal: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Load foods for a specific meal
    func loadMealFoods(mealId: UUID) async {
        do {
            selectedMealFoods = try await foodService.fetchMealFoods(mealId: mealId)
        } catch {
            errorMessage = "Failed to load meal foods: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Food Logging
    
    /// Log food entry
    func logFood(
        foodName: String,
        brandName: String?,
        servingSize: String,
        servingUnit: String,
        calories: Int,
        protein: Double,
        carbs: Double,
        fat: Double,
        fiber: Double?,
        sugar: Double?,
        sodium: Double?,
        servings: Double,
        mealType: MealType?,
        usdaFdcId: String? = nil,
        customFoodId: UUID? = nil,
        customMealId: UUID? = nil
    ) async -> Bool {
        guard let userId = userId else { return false }
        
        isLoading = true
        errorMessage = nil
        
        let request = FoodLogRequest(
            userId: userId,
            foodName: foodName,
            brandName: brandName,
            servingSize: servingSize,
            servingUnit: servingUnit,
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            fiber: fiber,
            sugar: sugar,
            sodium: sodium,
            servings: servings,
            mealType: mealType,
            usdaFdcId: usdaFdcId,
            customFoodId: customFoodId,
            customMealId: customMealId,
            loggedAt: Date()
        )
        
        do {
            let newLog = try await foodService.logFood(userId: userId, foodLog: request)
            todayFoodLogs.append(newLog)
            todayFoodLogs.sort { $0.loggedAt < $1.loggedAt }
            successMessage = "Food logged!"
            isLoading = false
            return true
        } catch {
            errorMessage = "Failed to log food: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    /// Delete food log
    func deleteFoodLog(_ log: FoodLog) async {
        guard let userId = userId else { return }
        
        do {
            try await foodService.deleteFoodLog(logId: log.id, userId: userId, loggedAt: log.loggedAt)
            todayFoodLogs.removeAll { $0.id == log.id }
            successMessage = "Food log deleted"
        } catch {
            errorMessage = "Failed to delete log: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Computed Properties
    
    /// Total calories consumed today
    var todayTotalCalories: Int {
        todayFoodLogs.reduce(0) { $0 + Int($1.totalCalories) }
    }
    
    /// Total protein consumed today
    var todayTotalProtein: Double {
        todayFoodLogs.reduce(0.0) { $0 + $1.totalProtein }
    }
    
    /// Total carbs consumed today
    var todayTotalCarbs: Double {
        todayFoodLogs.reduce(0.0) { $0 + $1.totalCarbs }
    }
    
    /// Total fat consumed today
    var todayTotalFat: Double {
        todayFoodLogs.reduce(0.0) { $0 + $1.totalFat }
    }
    
    /// Group food logs by meal type
    func foodLogsByMealType() -> [MealType: [FoodLog]] {
        Dictionary(grouping: todayFoodLogs) { $0.mealType ?? .snack }
    }
    
    // MARK: - Utility Methods
    
    /// Clear success/error messages
    func clearMessages() {
        successMessage = nil
        errorMessage = nil
    }
}

