//
//  FoodEntry.swift
//  Health App
//
//  Model for food logging with full macronutrients
//

import Foundation

/// Food log entry with nutritional information
struct FoodLog: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    
    // Food information
    var foodName: String
    var brandName: String?
    var servingSize: String // Serving size as string (e.g., "100", "1 cup")
    var servingUnit: String // "g", "ml", "cup", etc.
    
    // Nutritional information (per serving, before servings multiplier)
    var calories: Int
    var protein: Double // in grams
    var carbs: Double // in grams
    var fat: Double // in grams
    var fiber: Double? // in grams
    
    // Optional micronutrients
    var sugar: Double? // in grams
    var sodium: Double? // in mg
    
    // Serving information
    var servings: Double // Multiplier for serving size (default 1.0)
    
    // Meal information
    var mealType: MealType?
    
    // USDA FoodData Central reference
    var usdaFdcId: String?
    
    // Timestamps
    let loggedAt: Date
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
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
        case loggedAt = "logged_at"
        case createdAt = "created_at"
    }

    
    /// Calculate total calories including servings multiplier
    var totalCalories: Double {
        return Double(calories) * servings
    }
    
    /// Calculate total protein including servings multiplier
    var totalProtein: Double {
        return protein * servings
    }
    
    /// Calculate total carbs including servings multiplier
    var totalCarbs: Double {
        return carbs * servings
    }
    
    /// Calculate total fat including servings multiplier
    var totalFat: Double {
        return fat * servings
    }
    
    /// Format serving information for display
    var servingDescription: String {
        if servings == 1.0 {
            return "\(servingSize) \(servingUnit)"
        } else {
            return String(format: "%.1f × %@ %@", servings, servingSize, servingUnit)
        }
    }
}

// Legacy type alias for backward compatibility
typealias FoodEntry = FoodLog

/// Meal type for food entry organization
enum MealType: String, Codable, CaseIterable {
    case breakfast
    case lunch
    case dinner
    case snack
    
    var displayName: String {
        return self.rawValue.capitalized
    }
    
    var icon: String {
        switch self {
        case .breakfast: return "sunrise.fill"
        case .lunch: return "sun.max.fill"
        case .dinner: return "moon.stars.fill"
        case .snack: return "leaf.fill"
        }
    }
}

