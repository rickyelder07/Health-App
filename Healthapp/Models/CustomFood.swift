//
//  CustomFood.swift
//  Health App
//
//  Model for user-created custom foods
//

import Foundation

/// User-created custom food with full nutrition information
struct CustomFood: Codable, Identifiable, Hashable {
    let id: UUID
    let userId: UUID
    var name: String
    var brand: String?
    var calories: Int
    var protein: Double
    var carbs: Double
    var fat: Double
    var fiber: Double?
    var sugar: Double?
    var sodium: Double?
    var servingSize: String
    var servingUnit: String
    var isFavorite: Bool
    let createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case brand
        case calories
        case protein
        case carbs
        case fat
        case fiber
        case sugar
        case sodium
        case servingSize = "serving_size"
        case servingUnit = "serving_unit"
        case isFavorite = "is_favorite"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    /// Display name with brand if available
    var displayName: String {
        if let brand = brand, !brand.isEmpty {
            return "\(brand) - \(name)"
        }
        return name
    }
    
    /// Formatted serving information
    var servingDescription: String {
        return "\(servingSize) \(servingUnit)"
    }
    
    /// Calculate nutrition for a given quantity
    func nutrition(forQuantity quantity: Double) -> NutritionInfo {
        return NutritionInfo(
            calories: Int(Double(calories) * quantity),
            protein: protein * quantity,
            carbs: carbs * quantity,
            fat: fat * quantity,
            fiber: fiber.map { $0 * quantity },
            sugar: sugar.map { $0 * quantity },
            sodium: sodium.map { $0 * quantity }
        )
    }
}

/// Helper struct for nutrition calculations
struct NutritionInfo {
    let calories: Int
    let protein: Double
    let carbs: Double
    let fat: Double
    let fiber: Double?
    let sugar: Double?
    let sodium: Double?
}

/// Request model for creating custom food
struct CreateCustomFoodRequest: Codable {
    let userId: UUID
    let name: String
    let brand: String?
    let calories: Int
    let protein: Double
    let carbs: Double
    let fat: Double
    let fiber: Double?
    let sugar: Double?
    let sodium: Double?
    let servingSize: String
    let servingUnit: String
    let isFavorite: Bool
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case name
        case brand
        case calories
        case protein
        case carbs
        case fat
        case fiber
        case sugar
        case sodium
        case servingSize = "serving_size"
        case servingUnit = "serving_unit"
        case isFavorite = "is_favorite"
    }
}

/// Request model for updating custom food
struct UpdateCustomFoodRequest: Codable {
    let name: String?
    let brand: String?
    let calories: Int?
    let protein: Double?
    let carbs: Double?
    let fat: Double?
    let fiber: Double?
    let sugar: Double?
    let sodium: Double?
    let servingSize: String?
    let servingUnit: String?
    let isFavorite: Bool?
    
    enum CodingKeys: String, CodingKey {
        case name
        case brand
        case calories
        case protein
        case carbs
        case fat
        case fiber
        case sugar
        case sodium
        case servingSize = "serving_size"
        case servingUnit = "serving_unit"
        case isFavorite = "is_favorite"
    }
}

