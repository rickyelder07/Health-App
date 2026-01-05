//
//  CustomMeal.swift
//  Netfuel
//
//  Model for user-created custom meals (combinations of foods)
//

import Foundation

/// User-created custom meal composed of multiple foods
struct CustomMeal: Codable, Identifiable, Hashable {
    let id: UUID
    let userId: UUID
    var name: String
    var description: String?
    var totalCalories: Int
    var totalProtein: Double
    var totalCarbs: Double
    var totalFat: Double
    var isFavorite: Bool
    let createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case description
        case totalCalories = "total_calories"
        case totalProtein = "total_protein"
        case totalCarbs = "total_carbs"
        case totalFat = "total_fat"
        case isFavorite = "is_favorite"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    /// Calculate nutrition for a given multiplier (e.g., 0.5x or 2x)
    func nutrition(multiplier: Double) -> NutritionInfo {
        return NutritionInfo(
            calories: Int(Double(totalCalories) * multiplier),
            protein: totalProtein * multiplier,
            carbs: totalCarbs * multiplier,
            fat: totalFat * multiplier,
            fiber: nil,
            sugar: nil,
            sodium: nil
        )
    }
}

/// Food item within a custom meal
struct CustomMealFood: Codable, Identifiable, Hashable {
    let id: UUID
    let mealId: UUID
    let customFoodId: UUID?
    let usdaFdcId: String?
    var foodName: String
    var brandName: String?
    var quantity: Double
    var servingSize: String
    var servingUnit: String
    var calories: Int
    var protein: Double
    var carbs: Double
    var fat: Double
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case mealId = "meal_id"
        case customFoodId = "custom_food_id"
        case usdaFdcId = "usda_fdc_id"
        case foodName = "food_name"
        case brandName = "brand_name"
        case quantity
        case servingSize = "serving_size"
        case servingUnit = "serving_unit"
        case calories
        case protein
        case carbs
        case fat
        case createdAt = "created_at"
    }
    
    /// Display name with brand if available
    var displayName: String {
        if let brand = brandName, !brand.isEmpty {
            return "\(brand) - \(foodName)"
        }
        return foodName
    }
    
    /// Formatted quantity and serving
    var servingDescription: String {
        return String(format: "%.1fx %@ %@", quantity, servingSize, servingUnit)
    }
    
    /// Total nutrition for this food in the meal (calories * quantity already applied)
    var totalNutrition: NutritionInfo {
        return NutritionInfo(
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            fiber: nil,
            sugar: nil,
            sodium: nil
        )
    }
}

/// Request model for creating custom meal
struct CreateCustomMealRequest: Codable {
    let userId: UUID
    let name: String
    let description: String?
    let isFavorite: Bool
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case name
        case description
        case isFavorite = "is_favorite"
    }
}

/// Request model for updating custom meal
struct UpdateCustomMealRequest: Codable {
    let name: String?
    let description: String?
    let isFavorite: Bool?
    
    enum CodingKeys: String, CodingKey {
        case name
        case description
        case isFavorite = "is_favorite"
    }
}

/// Request model for adding food to meal
struct AddFoodToMealRequest: Codable {
    let mealId: UUID
    let customFoodId: UUID?
    let usdaFdcId: String?
    let foodName: String
    let brandName: String?
    let quantity: Double
    let servingSize: String
    let servingUnit: String
    let calories: Int
    let protein: Double
    let carbs: Double
    let fat: Double
    
    enum CodingKeys: String, CodingKey {
        case mealId = "meal_id"
        case customFoodId = "custom_food_id"
        case usdaFdcId = "usda_fdc_id"
        case foodName = "food_name"
        case brandName = "brand_name"
        case quantity
        case servingSize = "serving_size"
        case servingUnit = "serving_unit"
        case calories
        case protein
        case carbs
        case fat
    }
}

/// Update quantity of food in meal
struct UpdateMealFoodQuantityRequest: Codable {
    let quantity: Double
    let calories: Int
    let protein: Double
    let carbs: Double
    let fat: Double
    
    enum CodingKeys: String, CodingKey {
        case quantity
        case calories
        case protein
        case carbs
        case fat
    }
}

