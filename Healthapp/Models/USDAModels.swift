//
//  USDAModels.swift
//  Netfuel
//
//  Models for USDA FoodData Central API responses
//

import Foundation

/// USDA food search response
struct USDAFoodSearchResponse: Codable {
    let totalHits: Int
    let currentPage: Int
    let totalPages: Int
    let foods: [USDAFood]
}

/// USDA food item from search results
struct USDAFood: Codable, Identifiable {
    let fdcId: Int
    let description: String
    let brandOwner: String?
    let brandName: String?
    let ingredients: String?
    let servingSize: Double?
    let servingSizeUnit: String?
    let foodNutrients: [USDAFoodNutrient]?
    
    var id: Int { fdcId }
    
    enum CodingKeys: String, CodingKey {
        case fdcId
        case description
        case brandOwner
        case brandName
        case ingredients
        case servingSize
        case servingSizeUnit
        case foodNutrients
    }
    
    /// Get nutrient value by name
    func getNutrient(name: String) -> Double? {
        return foodNutrients?.first { $0.nutrientName.lowercased().contains(name.lowercased()) }?.value
    }
    
    /// Extract calories from nutrients
    var calories: Double? {
        return getNutrient(name: "energy")
    }
    
    /// Extract protein from nutrients
    var protein: Double? {
        return getNutrient(name: "protein")
    }
    
    /// Extract carbohydrates from nutrients
    var carbohydrates: Double? {
        return getNutrient(name: "carbohydrate")
    }
    
    /// Extract fat from nutrients
    var fat: Double? {
        return getNutrient(name: "total lipid") ?? getNutrient(name: "fat, total")
    }
}

/// USDA food nutrient information
struct USDAFoodNutrient: Codable {
    let nutrientId: Int?
    let nutrientName: String
    let nutrientNumber: String?
    let unitName: String
    let value: Double
    
    enum CodingKeys: String, CodingKey {
        case nutrientId
        case nutrientName
        case nutrientNumber
        case unitName
        case value
    }
}

/// USDA detailed food information
struct USDAFoodDetail: Codable {
    let fdcId: Int
    let description: String
    let brandOwner: String?
    let brandName: String?
    let ingredients: String?
    let servingSize: Double?
    let servingSizeUnit: String?
    let foodNutrients: [USDAFoodNutrientDetail]
    
    enum CodingKeys: String, CodingKey {
        case fdcId
        case description
        case brandOwner
        case brandName
        case ingredients
        case servingSize
        case servingSizeUnit
        case foodNutrients
    }
}

/// Detailed nutrient information from food detail endpoint
struct USDAFoodNutrientDetail: Codable {
    let nutrient: USDANutrient
    let amount: Double
    
    enum CodingKeys: String, CodingKey {
        case nutrient
        case amount
    }
}

/// USDA nutrient detail
struct USDANutrient: Codable {
    let id: Int
    let name: String
    let unitName: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case unitName
    }
}

