//
//  FoodService.swift
//  Health App
//
//  Service for food logging with USDA database integration and custom foods/meals
//

import Foundation
import Combine
import Supabase

/// Comprehensive service for managing food logging, custom foods, and meals
class FoodService {
    private let supabase = SupabaseClient.shared.client
    private let usdaService = USDAService()
    
    // MARK: - USDA Food Search
    
    /// Search for foods in USDA database
    func searchUSDAFoods(query: String, pageSize: Int = 25) async throws -> [USDAFood] {
        let response = try await usdaService.searchFoods(query: query, pageSize: pageSize)
        return response.foods
    }
    
    /// Get detailed USDA food information
    func getUSDAFoodDetails(fdcId: String) async throws -> USDAFoodDetail {
        return try await usdaService.getFoodDetails(fdcId: fdcId)
    }
    
    // MARK: - Custom Foods CRUD
    
    /// Create a new custom food
    func createCustomFood(request: CreateCustomFoodRequest) async throws -> CustomFood {
        let response = try await supabase
            .from("custom_foods")
            .insert(request)
            .select()
            .execute()
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let foods = try decoder.decode([CustomFood].self, from: response.data)
        
        guard let food = foods.first else {
            throw FoodServiceError.createFailed
        }
        
        return food
    }
    
    /// Fetch all custom foods for a user
    func fetchCustomFoods(userId: UUID, favoritesOnly: Bool = false) async throws -> [CustomFood] {
        let response = try await supabase
            .from("custom_foods")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .execute()
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let foods = try decoder.decode([CustomFood].self, from: response.data)
        
        // Filter favorites in-memory if needed
        if favoritesOnly {
            return foods.filter { $0.isFavorite }
        }
        
        return foods
    }
    
    /// Search custom foods by name
    func searchCustomFoods(userId: UUID, query: String) async throws -> [CustomFood] {
        let response = try await supabase
            .from("custom_foods")
            .select()
            .eq("user_id", value: userId.uuidString)
            .ilike("name", value: "%\(query)%")
            .order("is_favorite", ascending: false)
            .order("created_at", ascending: false)
            .execute()
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([CustomFood].self, from: response.data)
    }
    
    /// Update a custom food
    func updateCustomFood(foodId: UUID, request: UpdateCustomFoodRequest) async throws -> CustomFood {
        let response = try await supabase
            .from("custom_foods")
            .update(request)
            .eq("id", value: foodId.uuidString)
            .select()
            .execute()
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let foods = try decoder.decode([CustomFood].self, from: response.data)
        
        guard let food = foods.first else {
            throw FoodServiceError.updateFailed
        }
        
        return food
    }
    
    /// Delete a custom food
    func deleteCustomFood(foodId: UUID) async throws {
        try await supabase
            .from("custom_foods")
            .delete()
            .eq("id", value: foodId.uuidString)
            .execute()
    }
    
    /// Toggle favorite status of a custom food
    func toggleCustomFoodFavorite(foodId: UUID, isFavorite: Bool) async throws {
        _ = try await supabase
            .from("custom_foods")
            .update(["is_favorite": isFavorite])
            .eq("id", value: foodId.uuidString)
            .execute()
    }
    
    /// Create custom food from USDA food (copy)
    func createCustomFoodFromUSDA(usdaFood: USDAFood, userId: UUID) async throws -> CustomFood {
        let request = CreateCustomFoodRequest(
            userId: userId,
            name: usdaFood.description,
            brand: usdaFood.brandName ?? usdaFood.brandOwner,
            calories: Int(usdaFood.calories ?? 0),
            protein: usdaFood.protein ?? 0,
            carbs: usdaFood.carbohydrates ?? 0,
            fat: usdaFood.fat ?? 0,
            fiber: usdaFood.getNutrient(name: "fiber"),
            sugar: usdaFood.getNutrient(name: "sugar"),
            sodium: usdaFood.getNutrient(name: "sodium"),
            servingSize: usdaFood.servingSize.map { String(format: "%.0f", $0) } ?? "100",
            servingUnit: usdaFood.servingSizeUnit ?? "g",
            isFavorite: false
        )
        
        return try await createCustomFood(request: request)
    }
    
    // MARK: - Custom Meals CRUD
    
    /// Create a new custom meal
    func createCustomMeal(request: CreateCustomMealRequest) async throws -> CustomMeal {
        let response = try await supabase
            .from("custom_meals")
            .insert(request)
            .select()
            .execute()
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let meals = try decoder.decode([CustomMeal].self, from: response.data)
        
        guard let meal = meals.first else {
            throw FoodServiceError.createFailed
        }
        
        return meal
    }
    
    /// Fetch all custom meals for a user
    func fetchCustomMeals(userId: UUID, favoritesOnly: Bool = false) async throws -> [CustomMeal] {
        let response = try await supabase
            .from("custom_meals")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .execute()
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let meals = try decoder.decode([CustomMeal].self, from: response.data)
        
        // Filter favorites in-memory if needed
        if favoritesOnly {
            return meals.filter { $0.isFavorite }
        }
        
        return meals
    }
    
    /// Search custom meals by name
    func searchCustomMeals(userId: UUID, query: String) async throws -> [CustomMeal] {
        let response = try await supabase
            .from("custom_meals")
            .select()
            .eq("user_id", value: userId.uuidString)
            .ilike("name", value: "%\(query)%")
            .order("is_favorite", ascending: false)
            .order("created_at", ascending: false)
            .execute()
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([CustomMeal].self, from: response.data)
    }
    
    /// Update a custom meal
    func updateCustomMeal(mealId: UUID, request: UpdateCustomMealRequest) async throws -> CustomMeal {
        let response = try await supabase
            .from("custom_meals")
            .update(request)
            .eq("id", value: mealId.uuidString)
            .select()
            .execute()
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let meals = try decoder.decode([CustomMeal].self, from: response.data)
        
        guard let meal = meals.first else {
            throw FoodServiceError.updateFailed
        }
        
        return meal
    }
    
    /// Delete a custom meal
    func deleteCustomMeal(mealId: UUID) async throws {
        try await supabase
            .from("custom_meals")
            .delete()
            .eq("id", value: mealId.uuidString)
            .execute()
    }
    
    /// Toggle favorite status of a custom meal
    func toggleCustomMealFavorite(mealId: UUID, isFavorite: Bool) async throws {
        _ = try await supabase
            .from("custom_meals")
            .update(["is_favorite": isFavorite])
            .eq("id", value: mealId.uuidString)
            .execute()
    }
    
    /// Duplicate a custom meal
    func duplicateCustomMeal(mealId: UUID, newName: String, userId: UUID) async throws -> CustomMeal {
        // Fetch original meal
        let response = try await supabase
            .from("custom_meals")
            .select()
            .eq("id", value: mealId.uuidString)
            .execute()
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let originalMeals = try decoder.decode([CustomMeal].self, from: response.data)
        
        guard let original = originalMeals.first else {
            throw FoodServiceError.notFound
        }
        
        // Create new meal
        let newMealRequest = CreateCustomMealRequest(
            userId: userId,
            name: newName,
            description: original.description,
            isFavorite: false
        )
        let newMeal = try await createCustomMeal(request: newMealRequest)
        
        // Copy all foods from original meal
        let originalFoods = try await fetchMealFoods(mealId: mealId)
        
        for food in originalFoods {
            let addFoodRequest = AddFoodToMealRequest(
                mealId: newMeal.id,
                customFoodId: food.customFoodId,
                usdaFdcId: food.usdaFdcId,
                foodName: food.foodName,
                brandName: food.brandName,
                quantity: food.quantity,
                servingSize: food.servingSize,
                servingUnit: food.servingUnit,
                calories: food.calories,
                protein: food.protein,
                carbs: food.carbs,
                fat: food.fat
            )
            
            _ = try await addFoodToMeal(request: addFoodRequest)
        }
        
        // Fetch updated meal with totals
        let updatedResponse = try await supabase
            .from("custom_meals")
            .select()
            .eq("id", value: newMeal.id.uuidString)
            .execute()
        
        let updatedDecoder = JSONDecoder()
        updatedDecoder.dateDecodingStrategy = .iso8601
        let updatedMeals = try updatedDecoder.decode([CustomMeal].self, from: updatedResponse.data)
        
        return updatedMeals.first ?? newMeal
    }
    
    // MARK: - Meal Foods Management
    
    /// Add food to a meal
    func addFoodToMeal(request: AddFoodToMealRequest) async throws -> CustomMealFood {
        let response = try await supabase
            .from("custom_meal_foods")
            .insert(request)
            .select()
            .execute()
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let mealFoods = try decoder.decode([CustomMealFood].self, from: response.data)
        
        guard let mealFood = mealFoods.first else {
            throw FoodServiceError.createFailed
        }
        
        return mealFood
    }
    
    /// Fetch all foods in a meal
    func fetchMealFoods(mealId: UUID) async throws -> [CustomMealFood] {
        let response = try await supabase
            .from("custom_meal_foods")
            .select()
            .eq("meal_id", value: mealId.uuidString)
            .order("created_at", ascending: true)
            .execute()
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([CustomMealFood].self, from: response.data)
    }
    
    /// Update quantity of a food in a meal
    func updateMealFoodQuantity(mealFoodId: UUID, request: UpdateMealFoodQuantityRequest) async throws {
        _ = try await supabase
            .from("custom_meal_foods")
            .update(request)
            .eq("id", value: mealFoodId.uuidString)
            .execute()
    }
    
    /// Remove food from a meal
    func removeFoodFromMeal(mealFoodId: UUID) async throws {
        try await supabase
            .from("custom_meal_foods")
            .delete()
            .eq("id", value: mealFoodId.uuidString)
            .execute()
    }
    
    // MARK: - Food Logging
    
    /// Log food entry
    func logFood(userId: UUID, foodLog: FoodLogRequest) async throws -> FoodLog {
        let response = try await supabase
            .from("food_logs")
            .insert(foodLog)
            .select()
            .execute()
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let logs = try decoder.decode([FoodLog].self, from: response.data)
        
        guard let log = logs.first else {
            throw FoodServiceError.createFailed
        }
        
        // Update daily summary
        try await updateDailySummary(userId: userId, date: foodLog.loggedAt)
        
        return log
    }
    
    /// Fetch food logs for a specific date
    func fetchFoodLogs(userId: UUID, date: Date) async throws -> [FoodLog] {
        print("🍔 FoodService.fetchFoodLogs() - START")
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        print("🍔 Querying for user: \(userId), date range: \(startOfDay.ISO8601Format()) to \(endOfDay.ISO8601Format())")

        let response = try await supabase
            .from("food_logs")
            .select()
            .eq("user_id", value: userId.uuidString)
            .gte("logged_at", value: startOfDay.ISO8601Format())
            .lt("logged_at", value: endOfDay.ISO8601Format())
            .order("logged_at", ascending: true)
            .execute()

        print("🍔 Response data: \(String(data: response.data, encoding: .utf8) ?? "nil")")

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let logs = try decoder.decode([FoodLog].self, from: response.data)
        print("🍔 Decoded \(logs.count) food logs")

        return logs
    }
    
    /// Delete food log
    func deleteFoodLog(logId: UUID, userId: UUID, loggedAt: Date) async throws {
        try await supabase
            .from("food_logs")
            .delete()
            .eq("id", value: logId.uuidString)
            .execute()
        
        // Update daily summary
        try await updateDailySummary(userId: userId, date: loggedAt)
    }
    
    /// Fetch recently logged foods (for quick add)
    func fetchRecentFoods(userId: UUID, limit: Int = 10) async throws -> [FoodLog] {
        let response = try await supabase
            .from("food_logs")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("logged_at", ascending: false)
            .limit(limit)
            .execute()
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([FoodLog].self, from: response.data)
    }
    
    /// Fetch most frequently logged foods
    func fetchMostLoggedFoods(userId: UUID, limit: Int = 10) async throws -> [(String, Int)] {
        // This would require a database function or aggregation
        // For now, return empty array - implement server-side aggregation in production
        return []
    }
    
    // MARK: - Daily Summary Update
    
    /// Update daily summary after logging food
    /// Delegates to DailySummaryService for comprehensive calculation
    private func updateDailySummary(userId: UUID, date: Date) async throws {
        let summaryService = DailySummaryService()
        try await summaryService.updateFoodConsumption(userId: userId, date: date)
    }
}

// MARK: - Supporting Models

/// Request model for logging food
struct FoodLogRequest: Codable {
    let userId: UUID
    let foodName: String
    let brandName: String?
    let servingSize: String
    let servingUnit: String
    let calories: Int
    let protein: Double
    let carbs: Double
    let fat: Double
    let fiber: Double?
    let sugar: Double?
    let sodium: Double?
    let servings: Double
    let mealType: MealType?
    let usdaFdcId: String?
    let customFoodId: UUID?
    let customMealId: UUID?
    let loggedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case foodName = "food_name"
        case brandName = "brand_name"
        case servingSize = "serving_size"
        case servingUnit = "serving_unit"
        case calories
        case protein
        case carbs
        case fat
        case fiber
        case sugar
        case sodium
        case servings
        case mealType = "meal_type"
        case usdaFdcId = "usda_fdc_id"
        case customFoodId = "custom_food_id"
        case customMealId = "custom_meal_id"
        case loggedAt = "logged_at"
    }
}

/// Request model for daily summary
struct DailySummaryRequest: Codable {
    let userId: UUID
    let date: Date
    let caloriesConsumed: Int?
    let proteinConsumed: Double?
    let carbsConsumed: Double?
    let fatConsumed: Double?
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case date
        case caloriesConsumed = "calories_consumed"
        case proteinConsumed = "protein_consumed"
        case carbsConsumed = "carbs_consumed"
        case fatConsumed = "fat_consumed"
    }
}

/// Request model for updating daily summary
struct DailySummaryUpdateRequest: Codable {
    let caloriesConsumed: Int
    let proteinConsumed: Double
    let carbsConsumed: Double
    let fatConsumed: Double
    
    enum CodingKeys: String, CodingKey {
        case caloriesConsumed = "calories_consumed"
        case proteinConsumed = "protein_consumed"
        case carbsConsumed = "carbs_consumed"
        case fatConsumed = "fat_consumed"
    }
}

// MARK: - Error Handling

/// Food service errors
enum FoodServiceError: LocalizedError {
    case createFailed
    case updateFailed
    case deleteFailed
    case notFound
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .createFailed:
            return "Failed to create item."
        case .updateFailed:
            return "Failed to update item."
        case .deleteFailed:
            return "Failed to delete item."
        case .notFound:
            return "Item not found."
        case .invalidData:
            return "Invalid data provided."
        }
    }
}

